const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const { neon } = require('@neondatabase/serverless');

const app = express();
const server = http.createServer(app);

// Configure CORS
app.use(cors({
  origin: ['https://tokerrgjik.netlify.app', 'http://localhost:*'],
  credentials: true
}));

const io = socketIo(server, {
  cors: {
    origin: ['https://tokerrgjik.netlify.app', 'http://localhost:*'],
    methods: ['GET', 'POST'],
    credentials: true
  }
});

// Initialize Neon database
const sql = neon(process.env.NEON_DATABASE_URL);

// Store active game sessions
const activeSessions = new Map();
const waitingPlayers = new Map();

io.on('connection', (socket) => {
  console.log('User connected:', socket.id);
  
  // Player joins lobby
  socket.on('join_lobby', async (data) => {
    const { username } = data;
    console.log(`${username} joined lobby`);
    
    socket.username = username;
    socket.join('lobby');
    
    // Emit updated lobby count
    const lobbyCount = io.sockets.adapter.rooms.get('lobby')?.size || 0;
    io.to('lobby').emit('lobby_update', { playersOnline: lobbyCount });
  });
  
  // Player creates a game session
  socket.on('create_session', async (data) => {
    const { username, isPrivate, invitedUsername } = data;
    
    try {
      // Create session in database
      const result = await sql`
        INSERT INTO game_sessions (host_username, guest_username, status, board_state, current_turn)
        VALUES (${username}, ${invitedUsername || null}, 'waiting', '{}', ${username})
        RETURNING *
      `;
      
      const session = result[0];
      const sessionId = session.id;
      
      activeSessions.set(sessionId, {
        hostSocket: socket.id,
        hostUsername: username,
        guestSocket: null,
        guestUsername: invitedUsername,
        board: Array(24).fill(null),
        currentTurn: username,
        hostPieces: 9,
        guestPieces: 9,
        phase: 'placement', // placement, movement, flying
        selectedPosition: null,
      });
      
      socket.sessionId = sessionId;
      socket.join(`session_${sessionId}`);
      
      console.log(`Session ${sessionId} created by ${username}`);
      
      socket.emit('session_created', {
        sessionId,
        host: username,
        status: 'waiting'
      });
      
      // If not private, add to waiting list
      if (!isPrivate) {
        waitingPlayers.set(sessionId, {
          hostUsername: username,
          hostSocket: socket.id,
          createdAt: Date.now()
        });
        
        // Broadcast available sessions to lobby
        io.to('lobby').emit('sessions_updated', {
          sessions: Array.from(waitingPlayers.entries()).map(([id, data]) => ({
            sessionId: id,
            hostUsername: data.hostUsername,
          }))
        });
      }
      
    } catch (error) {
      console.error('Error creating session:', error);
      socket.emit('error', { message: 'Failed to create session' });
    }
  });
  
  // Player joins an existing session
  socket.on('join_session', async (data) => {
    const { sessionId, username } = data;
    
    const session = activeSessions.get(sessionId);
    if (!session) {
      socket.emit('error', { message: 'Session not found' });
      return;
    }
    
    if (session.guestSocket) {
      socket.emit('error', { message: 'Session is full' });
      return;
    }
    
    session.guestSocket = socket.id;
    session.guestUsername = username;
    
    socket.sessionId = sessionId;
    socket.username = username;
    socket.join(`session_${sessionId}`);
    
    // Update database
    try {
      await sql`
        UPDATE game_sessions
        SET guest_username = ${username}, status = 'active', updated_at = NOW()
        WHERE id = ${sessionId}
      `;
    } catch (error) {
      console.error('Error updating session:', error);
    }
    
    // Remove from waiting list
    waitingPlayers.delete(sessionId);
    
    console.log(`✅ ${username} joined session ${sessionId}`);
    
    // Notify HOST that a player joined
    io.to(session.hostSocket).emit('playerJoined', {
      username: username,
      message: `${username} has joined your game!`,
      sessionId: sessionId
    });
    
    // Notify both players that game is starting
    io.to(`session_${sessionId}`).emit('game_started', {
      sessionId,
      host: session.hostUsername,
      guest: username,
      currentTurn: session.currentTurn,
      board: session.board,
    });
    
    // Broadcast session update
    io.to(`session_${sessionId}`).emit('sessionUpdate', {
      sessionId,
      status: 'active',
      host: session.hostUsername,
      guest: username,
      currentTurn: session.currentTurn
    });
    
    // Update lobby
    io.to('lobby').emit('sessions_updated', {
      sessions: Array.from(waitingPlayers.entries()).map(([id, data]) => ({
        sessionId: id,
        hostUsername: data.hostUsername,
      }))
    });
  });
  
  // Player makes a move
  socket.on('make_move', async (data) => {
    const { sessionId, position, action } = data; // action: 'place', 'move', 'remove'
    const session = activeSessions.get(sessionId);
    
    if (!session) {
      socket.emit('error', { message: 'Session not found' });
      return;
    }
    
    const username = socket.username;
    
    // Verify it's player's turn
    if (session.currentTurn !== username) {
      socket.emit('error', { message: 'Not your turn' });
      return;
    }
    
    // Process move based on action
    let moveValid = false;
    
    if (action === 'place') {
      if (session.board[position] === null) {
        session.board[position] = username === session.hostUsername ? 'host' : 'guest';
        
        if (username === session.hostUsername) {
          session.hostPieces--;
        } else {
          session.guestPieces--;
        }
        
        moveValid = true;
      }
    } else if (action === 'move') {
      // Implement move logic (check adjacency, etc.)
      moveValid = true; // Simplified
    } else if (action === 'remove') {
      // Remove opponent's piece
      session.board[position] = null;
      moveValid = true;
    }
    
    if (moveValid) {
      // Switch turns
      session.currentTurn = session.currentTurn === session.hostUsername 
        ? session.guestUsername 
        : session.hostUsername;
      
      // Broadcast move to both players
      io.to(`session_${sessionId}`).emit('move_made', {
        position,
        action,
        board: session.board,
        currentTurn: session.currentTurn,
        hostPieces: session.hostPieces,
        guestPieces: session.guestPieces,
      });
      
      // Save to database
      try {
        await sql`
          UPDATE game_sessions
          SET board_state = ${JSON.stringify(session.board)},
              current_turn = ${session.currentTurn}
          WHERE id = ${sessionId}
        `;
      } catch (error) {
        console.error('Error saving move:', error);
      }
      
      // Check for win condition
      // (Implement win detection logic here)
    }
  });
  
  // Player sends chat message
  socket.on('send_message', (data) => {
    const { sessionId, message } = data;
    io.to(`session_${sessionId}`).emit('chat_message', {
      username: socket.username,
      message,
      timestamp: Date.now(),
    });
  });
  
  // Player disconnects
  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
    
    const sessionId = socket.sessionId;
    if (sessionId) {
      const session = activeSessions.get(sessionId);
      if (session) {
        // Notify other player
        io.to(`session_${sessionId}`).emit('player_disconnected', {
          username: socket.username
        });
        
        // Clean up session
        activeSessions.delete(sessionId);
        waitingPlayers.delete(sessionId);
        
        // Update database
        sql`
          UPDATE game_sessions
          SET status = 'cancelled'
          WHERE id = ${sessionId}
        `.catch(err => console.error('Error updating session on disconnect:', err));
      }
    }
    
    // Update lobby count
    const lobbyCount = io.sockets.adapter.rooms.get('lobby')?.size || 0;
    io.to('lobby').emit('lobby_update', { playersOnline: lobbyCount });
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    activeSessions: activeSessions.size,
    waitingPlayers: waitingPlayers.size,
    timestamp: new Date().toISOString()
  });
});

const PORT = process.env.PORT || 3001;
server.listen(PORT, () => {
  console.log(`🚀 Socket.IO server running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
});
