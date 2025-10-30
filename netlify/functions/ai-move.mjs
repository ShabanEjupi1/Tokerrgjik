import { HfInference } from '@huggingface/inference';

const HF_TOKEN = process.env.HUGGINGFACE_TOKEN || process.env.HF_TOKEN;

if (!HF_TOKEN) {
  console.warn('⚠️ HUGGINGFACE_TOKEN not set! AI moves will use fallback logic.');
}

const hf = HF_TOKEN ? new HfInference(HF_TOKEN) : null;

/**
 * AI Move Generator using Hugging Face models
 * Provides intelligent game moves for Nine Men's Morris (Tokerrgjik)
 * 
 * SETUP: Add HUGGINGFACE_TOKEN to Netlify environment variables
 */
export async function handler(event, context) {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Content-Type': 'application/json',
  };

  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 200, headers, body: '' };
  }

  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers,
      body: JSON.stringify({ error: 'Method not allowed' }),
    };
  }

  try {
    const { board, phase, difficulty, player, validMoves } = JSON.parse(event.body || '{}');

    if (!board || !phase || !player) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'Missing required fields: board, phase, player' }),
      };
    }

    // If HuggingFace is not configured, use enhanced fallback
    if (!hf) {
      const move = getEnhancedFallbackMove(board, phase, difficulty, player, validMoves);
      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({ move, strategy: 'Enhanced fallback logic' }),
      };
    }

    // Use Hugging Face model for intelligent moves
    const move = await getAIMove(board, phase, difficulty, player, validMoves);

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ move, strategy: 'HuggingFace AI' }),
    };

  } catch (error) {
    console.error('AI Move error:', error);
    
    // Fallback to basic logic if AI fails
    const { board, phase, difficulty, player, validMoves } = JSON.parse(event.body || '{}');
    const move = getEnhancedFallbackMove(board, phase, difficulty, player, validMoves);
    
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ 
        move, 
        strategy: 'Fallback due to error',
        error: error.message 
      }),
    };
  }
}

/**
 * Get AI move using Hugging Face models
 */
async function getAIMove(board, phase, difficulty, player, validMoves) {
  try {
    // Create a text representation of the game state
    const gameState = `
Nine Men's Morris Game State:
Phase: ${phase}
Player: ${player}
Difficulty: ${difficulty}
Board: ${JSON.stringify(board)}
Valid Moves: ${JSON.stringify(validMoves)}

Analyze the board and suggest the best move. Consider:
1. Blocking opponent's mills
2. Creating your own mills
3. Strategic positioning
4. Controlling key positions (center and middle ring)

Respond with only the move in JSON format: {"action": "place/move/remove", "position": number, "from": number (if moving)}
`;

    // Use a reasoning model for game strategy
    const response = await hf.textGeneration({
      model: 'mistralai/Mixtral-8x7B-Instruct-v0.1',
      inputs: gameState,
      parameters: {
        max_new_tokens: 150,
        temperature: difficulty === 'hard' ? 0.3 : difficulty === 'medium' ? 0.5 : 0.7,
        top_p: 0.9,
        return_full_text: false,
      },
    });

    // Parse AI response
    const aiMove = parseAIResponse(response.generated_text, board, phase, player, validMoves);
    return aiMove;

  } catch (error) {
    console.error('HuggingFace API error:', error);
    return getEnhancedFallbackMove(board, phase, difficulty, player, validMoves);
  }
}

/**
 * Parse AI model response and validate move
 */
function parseAIResponse(text, board, phase, player, validMoves) {
  try {
    // Try to extract JSON from response
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      const move = JSON.parse(jsonMatch[0]);
      
      // Validate move based on phase
      if (phase === 'placing' && move.action === 'place' && board[move.position] === null) {
        return { type: 'place', position: move.position };
      } else if (phase === 'moving' && move.action === 'move' && validMoves?.includes(move.position)) {
        return { type: 'move', from: move.from, to: move.position };
      } else if (phase === 'removing' && move.action === 'remove') {
        return { type: 'remove', position: move.position };
      }
    }
  } catch (e) {
    console.error('Failed to parse AI response:', e);
  }

  // If parsing fails, use enhanced fallback
  return getEnhancedFallbackMove(board, phase, difficulty, player, validMoves);
}

/**
 * Enhanced fallback AI logic (when HuggingFace is unavailable)
 * Uses strategic positioning and mill detection
 */
function getEnhancedFallbackMove(board, phase, difficulty, player, validMoves) {
  const opponent = player === 1 ? 2 : 1;

  // Mill patterns (positions that form mills)
  const millPatterns = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],       // Outer ring horizontal
    [9, 10, 11], [12, 13, 14], [15, 16, 17], // Middle ring horizontal
    [18, 19, 20], [21, 22, 23],            // Inner ring horizontal
    [0, 9, 18], [3, 12, 21], [6, 15, 24],  // Left vertical
    [1, 10, 19], [4, 13, 22], [7, 16, 25], // Middle vertical
    [2, 11, 20], [5, 14, 23], [8, 17, 26], // Right vertical
  ];

  // Strategic positions (center and key intersections)
  const strategicPositions = [4, 13, 22, 1, 10, 19, 7, 16, 25];

  if (phase === 'placing') {
    // 1. Try to complete a mill
    for (const pattern of millPatterns) {
      const positions = pattern.map(p => board[p]);
      const playerCount = positions.filter(p => p === player).length;
      const emptyCount = positions.filter(p => p === null).length;

      if (playerCount === 2 && emptyCount === 1) {
        const emptyPos = pattern[positions.findIndex(p => p === null)];
        if (board[emptyPos] === null) {
          return { type: 'place', position: emptyPos };
        }
      }
    }

    // 2. Block opponent's mill
    if (difficulty !== 'easy') {
      for (const pattern of millPatterns) {
        const positions = pattern.map(p => board[p]);
        const opponentCount = positions.filter(p => p === opponent).length;
        const emptyCount = positions.filter(p => p === null).length;

        if (opponentCount === 2 && emptyCount === 1) {
          const emptyPos = pattern[positions.findIndex(p => p === null)];
          if (board[emptyPos] === null) {
            return { type: 'place', position: emptyPos };
          }
        }
      }
    }

    // 3. Place on strategic positions
    for (const pos of strategicPositions) {
      if (board[pos] === null) {
        return { type: 'place', position: pos };
      }
    }

    // 4. Place on any empty position
    const emptyPositions = board.map((v, i) => v === null ? i : -1).filter(i => i >= 0);
    return { type: 'place', position: emptyPositions[Math.floor(Math.random() * emptyPositions.length)] };
  }

  if (phase === 'removing') {
    // Target opponent pieces that are part of potential mills
    for (const pattern of millPatterns) {
      const positions = pattern.map(p => board[p]);
      const opponentCount = positions.filter(p => p === opponent).length;

      if (opponentCount === 2) {
        const opponentPos = pattern.filter(p => board[p] === opponent)[0];
        return { type: 'remove', position: opponentPos };
      }
    }

    // Remove any opponent piece
    const opponentPieces = board.map((v, i) => v === opponent ? i : -1).filter(i => i >= 0);
    return { type: 'remove', position: opponentPieces[Math.floor(Math.random() * opponentPieces.length)] };
  }

  if (phase === 'moving') {
    // Try to form mills by moving
    const playerPieces = board.map((v, i) => v === player ? i : -1).filter(i => i >= 0);
    
    for (const from of playerPieces) {
      const moves = getValidMovesFrom(from, board);
      
      for (const to of moves) {
        // Simulate move
        const testBoard = [...board];
        testBoard[from] = null;
        testBoard[to] = player;

        // Check if move forms a mill
        if (isPartOfMill(to, player, testBoard)) {
          return { type: 'move', from, to };
        }
      }
    }

    // Move to strategic position
    for (const from of playerPieces) {
      const moves = getValidMovesFrom(from, board);
      
      for (const pos of strategicPositions) {
        if (moves.includes(pos)) {
          return { type: 'move', from, to: pos };
        }
      }
    }

    // Random valid move
    const from = playerPieces[Math.floor(Math.random() * playerPieces.length)];
    const moves = getValidMovesFrom(from, board);
    const to = moves[Math.floor(Math.random() * moves.length)];
    return { type: 'move', from, to };
  }

  return null;
}

function getValidMovesFrom(position, board) {
  const adjacency = {
    0: [1, 9], 1: [0, 2, 10], 2: [1, 11],
    3: [4, 12], 4: [3, 5, 13], 5: [4, 14],
    6: [7, 15], 7: [6, 8, 16], 8: [7, 17],
    9: [0, 10, 18], 10: [1, 9, 11, 19], 11: [2, 10, 20],
    12: [3, 13, 21], 13: [4, 12, 14, 22], 14: [5, 13, 23],
    15: [6, 16, 24], 16: [7, 15, 17, 25], 17: [8, 16, 26],
    18: [9, 19], 19: [10, 18, 20], 20: [11, 19],
    21: [12, 22], 22: [13, 21, 23], 23: [14, 22],
    24: [15, 25], 25: [16, 24, 26], 26: [17, 25],
  };

  return (adjacency[position] || []).filter(pos => board[pos] === null);
}

function isPartOfMill(position, player, board) {
  const millPatterns = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [9, 10, 11], [12, 13, 14], [15, 16, 17],
    [18, 19, 20], [21, 22, 23],
    [0, 9, 18], [3, 12, 21], [6, 15, 24],
    [1, 10, 19], [4, 13, 22], [7, 16, 25],
    [2, 11, 20], [5, 14, 23], [8, 17, 26],
  ];

  return millPatterns.some(pattern => 
    pattern.includes(position) &&
    pattern.every(p => board[p] === player)
  );
}
