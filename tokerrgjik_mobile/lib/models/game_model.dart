import 'dart:math';

class Position {
  final double x;
  final double y;
  final int id;

  Position({required this.x, required this.y, required this.id});
}

class GameModel {
  // Board state
  List<int?> board = List.filled(24, null);
  int currentPlayer = 1;
  String phase = 'placing'; // placing, moving, removing
  Map<int, int> piecesLeft = {1: 9, 2: 9};
  Map<int, int> piecesOnBoard = {1: 0, 2: 0};
  int? selectedPosition;
  bool aiEnabled = false;
  int aiPlayer = 2;
  String aiDifficulty = 'medium'; // AI difficulty level: easy, medium, hard, expert
  
  // Shilevek bonus: Track repeated mills for smart play rewards
  final List<int> _recentMillPositions = [];
  static const int shilevekBonusCoins = 20; // Bonus coins for repeated mill mastery
  Function(int coins, String reason)? onBonusEarned; // Callback for awarding bonus coins
  
  // Undo/Redo functionality
  final List<GameSnapshot> _history = [];
  final List<GameSnapshot> _redoStack = [];
  static const int maxHistorySize = 50;
  
  // Helper class to store game state
  GameSnapshot _captureState() {
    return GameSnapshot(
      board: List.from(board),
      currentPlayer: currentPlayer,
      phase: phase,
      piecesLeft: Map.from(piecesLeft),
      piecesOnBoard: Map.from(piecesOnBoard),
    );
  }
  
  void _saveState() {
    _history.add(_captureState());
    if (_history.length > maxHistorySize) {
      _history.removeAt(0);
    }
    _redoStack.clear(); // Clear redo stack on new action
  }
  
  bool canUndo() => _history.length > 1;
  bool canRedo() => _redoStack.isNotEmpty;
  
  void undo() {
    if (!canUndo()) return;
    
    // Save current state to redo stack
    _redoStack.add(_captureState());
    
    // Remove current state
    _history.removeLast();
    
    // Restore previous state
    final previousState = _history.last;
    _restoreState(previousState);
  }
  
  void redo() {
    if (!canRedo()) return;
    
    // Save current state to history
    _history.add(_captureState());
    
    // Restore state from redo stack
    final nextState = _redoStack.removeLast();
    _restoreState(nextState);
  }
  
  void _restoreState(GameSnapshot state) {
    board = List.from(state.board);
    currentPlayer = state.currentPlayer;
    phase = state.phase;
    piecesLeft = Map.from(state.piecesLeft);
    piecesOnBoard = Map.from(state.piecesOnBoard);
    selectedPosition = null;
  }

  // Board positions (normalized 0-1 coordinates)
  static final List<Position> positions = [
    // Outer square (0-7)
    Position(x: 0.1, y: 0.1, id: 0),
    Position(x: 0.5, y: 0.1, id: 1),
    Position(x: 0.9, y: 0.1, id: 2),
    Position(x: 0.9, y: 0.5, id: 3),
    Position(x: 0.9, y: 0.9, id: 4),
    Position(x: 0.5, y: 0.9, id: 5),
    Position(x: 0.1, y: 0.9, id: 6),
    Position(x: 0.1, y: 0.5, id: 7),
    // Middle square (8-15)
    Position(x: 0.25, y: 0.25, id: 8),
    Position(x: 0.5, y: 0.25, id: 9),
    Position(x: 0.75, y: 0.25, id: 10),
    Position(x: 0.75, y: 0.5, id: 11),
    Position(x: 0.75, y: 0.75, id: 12),
    Position(x: 0.5, y: 0.75, id: 13),
    Position(x: 0.25, y: 0.75, id: 14),
    Position(x: 0.25, y: 0.5, id: 15),
    // Inner square (16-23)
    Position(x: 0.4, y: 0.4, id: 16),
    Position(x: 0.5, y: 0.4, id: 17),
    Position(x: 0.6, y: 0.4, id: 18),
    Position(x: 0.6, y: 0.5, id: 19),
    Position(x: 0.6, y: 0.6, id: 20),
    Position(x: 0.5, y: 0.6, id: 21),
    Position(x: 0.4, y: 0.6, id: 22),
    Position(x: 0.4, y: 0.5, id: 23),
  ];

  // Connections between positions
  static final Map<int, List<int>> connections = {
    0: [1, 7], 1: [0, 2, 9], 2: [1, 3], 3: [2, 4, 11],
    4: [3, 5], 5: [4, 6, 13], 6: [5, 7], 7: [6, 0, 15],
    8: [9, 15], 9: [8, 10, 1, 17], 10: [9, 11], 11: [10, 12, 3, 19],
    12: [11, 13], 13: [12, 14, 5, 21], 14: [13, 15], 15: [14, 8, 7, 23],
    16: [17, 23], 17: [16, 18, 9], 18: [17, 19], 19: [18, 20, 11],
    20: [19, 21], 21: [20, 22, 13], 22: [21, 23], 23: [22, 16, 15]
  };

  // All possible mills
  static final List<List<int>> mills = [
    [0, 1, 2], [2, 3, 4], [4, 5, 6], [6, 7, 0],
    [8, 9, 10], [10, 11, 12], [12, 13, 14], [14, 15, 8],
    [16, 17, 18], [18, 19, 20], [20, 21, 22], [22, 23, 16],
    [1, 9, 17], [3, 11, 19], [5, 13, 21], [7, 15, 23]
  ];

  // Place a piece on the board
  bool placePiece(int posId) {
    if (board[posId] != null) return false;
    if (piecesLeft[currentPlayer]! == 0) return false;

    _saveState(); // Save state before making move
    
    board[posId] = currentPlayer;
    piecesLeft[currentPlayer] = piecesLeft[currentPlayer]! - 1;
    piecesOnBoard[currentPlayer] = piecesOnBoard[currentPlayer]! + 1;

    if (checkMill(posId)) {
      phase = 'removing';
      return true; // Mill formed - DO NOT switch player, they must remove a piece
    }

    // Check if placement phase is over
    if (piecesLeft[1]! == 0 && piecesLeft[2]! == 0) {
      phase = 'moving';
    }

    // No mill - automatically switch to next player
    switchPlayer();
    return false; // No mill
  }

  // Move a piece
  bool movePiece(int from, int to) {
    if (board[from] != currentPlayer) return false;
    if (board[to] != null) return false;

    _saveState(); // Save state before making move
    
    // Check if move is valid
    bool canFly = piecesOnBoard[currentPlayer]! == 3;
    bool isAdjacent = connections[from]?.contains(to) ?? false;

    if (!canFly && !isAdjacent) return false;

    // Make the move
    board[to] = board[from];
    board[from] = null;

    if (checkMill(to)) {
      // SHILEVEK BONUS: Reward smart players who create repeated mills!
      // If this position was used to form a mill recently, it means the player
      // is playing very strategically (shilevek technique) - reward them!
      if (_recentMillPositions.contains(to)) {
        // This is a repeated mill (shilevek) - BONUS COINS!
        onBonusEarned?.call(shilevekBonusCoins, 'Shilevek ekspert! Formim i përsëritur i dangut');
      }
      
      // Track this mill position
      _recentMillPositions.add(to);
      if (_recentMillPositions.length > 5) {
        _recentMillPositions.removeAt(0); // Keep reasonable history
      }
      
      phase = 'removing';
      return true; // Mill formed - DO NOT switch player, they must remove a piece
    }

    // No mill - automatically switch to next player
    switchPlayer();
    return false; // No mill
  }

  // Remove opponent's piece
  bool removePiece(int posId) {
    int opponent = currentPlayer == 1 ? 2 : 1;

    if (board[posId] != opponent) return false;

    _saveState(); // Save state before making move
    
    // Check if piece is in a mill
    bool inMill = checkMill(posId);
    if (inMill) {
      // Check if all opponent pieces are in mills
      bool hasNonMillPieces = false;
      for (int i = 0; i < 24; i++) {
        if (board[i] == opponent && !checkMill(i)) {
          hasNonMillPieces = true;
          break;
        }
      }
      if (hasNonMillPieces) return false; // Can't remove piece in mill
    }

    board[posId] = null;
    piecesOnBoard[opponent] = piecesOnBoard[opponent]! - 1;

    // Return to appropriate phase and switch player
    if (piecesLeft[1]! == 0 && piecesLeft[2]! == 0) {
      phase = 'moving';
    } else {
      phase = 'placing';
    }
    
    // After removing opponent's piece, switch to opponent's turn
    switchPlayer();

    return true;
  }

  // Check if position forms a mill
  bool checkMill(int posId) {
    int? player = board[posId];
    if (player == null) return false;

    return mills.any((mill) =>
        mill.contains(posId) && mill.every((pos) => board[pos] == player));
  }

  // Check win condition
  bool checkWinCondition() {
    int opponent = currentPlayer == 1 ? 2 : 1;

    // Win if opponent has only 2 pieces
    if (piecesOnBoard[opponent]! < 3 && piecesLeft[opponent]! == 0) {
      return true;
    }

    // Win if opponent cannot move (blocked - in moving phase)
    if (phase == 'moving' && piecesLeft[opponent]! == 0) {
      bool canMove = false;
      for (int i = 0; i < 24; i++) {
        if (board[i] == opponent) {
          // Check if this piece can move
          if (piecesOnBoard[opponent]! == 3) {
            // Can fly to any empty position
            if (board.any((piece) => piece == null)) {
              canMove = true;
              break;
            }
          } else {
            // Check adjacent positions
            List<int>? adjacent = connections[i];
            if (adjacent != null &&
                adjacent.any((pos) => board[pos] == null)) {
              canMove = true;
              break;
            }
          }
        }
      }
      return !canMove;
    }

    return false;
  }

  // Check if current player has no valid moves (blocked)
  bool isPlayerBlocked() {
    // Only check during moving phase
    if (phase != 'moving' || piecesLeft[currentPlayer]! > 0) {
      return false;
    }

    // Get all pieces of current player
    List<int> playerPieces = [];
    for (int i = 0; i < 24; i++) {
      if (board[i] == currentPlayer) {
        playerPieces.add(i);
      }
    }

    // Check if any piece has valid moves
    for (int piecePos in playerPieces) {
      if (getValidMoves(piecePos).isNotEmpty) {
        return false; // Has at least one valid move
      }
    }

    return true; // No valid moves - blocked!
  }

  // Switch to next player
  void switchPlayer() {
    currentPlayer = currentPlayer == 1 ? 2 : 1;
  }

  // Reset game
  void reset() {
    board = List.filled(24, null);
    currentPlayer = 1;
    phase = 'placing';
    piecesLeft = {1: 9, 2: 9};
    piecesOnBoard = {1: 0, 2: 0};
    selectedPosition = null;
    _recentMillPositions.clear(); // Clear shilevek tracking for new game
    _history.clear();
    _redoStack.clear();
    _saveState(); // Save initial state
  }

  // Get status message
  String getStatusMessage() {
    if (checkWinCondition()) {
      return 'Lojtari $currentPlayer fitoi! 🎉';
    }

    String action = '';
    switch (phase) {
      case 'placing':
        action = 'Vendos figurën';
        break;
      case 'moving':
        action = selectedPosition == null
            ? 'Zgjidh figurën për ta lëvizur'
            : 'Zgjidh ku ta lëvizësh';
        break;
      case 'removing':
        action = 'Hiq figurën e kundërshtarit';
        break;
    }

    return 'Lojtari $currentPlayer: $action';
  }

  // Get valid moves for a position
  List<int> getValidMoves(int fromPos) {
    if (board[fromPos] != currentPlayer) return [];

    bool canFly = piecesOnBoard[currentPlayer]! == 3;

    if (canFly) {
      // Can move to any empty position
      return board
          .asMap()
          .entries
          .where((entry) => entry.value == null)
          .map((entry) => entry.key)
          .toList();
    } else {
      // Can only move to adjacent empty positions
      return (connections[fromPos] ?? [])
          .where((pos) => board[pos] == null)
          .toList();
    }
  }

  // Get removable pieces
  List<int> getRemovablePieces() {
    int opponent = currentPlayer == 1 ? 2 : 1;
    List<int> removable = [];
    bool hasNonMillPieces = false;

    for (int i = 0; i < 24; i++) {
      if (board[i] == opponent) {
        if (!checkMill(i)) {
          removable.add(i);
          hasNonMillPieces = true;
        }
      }
    }

    // If all pieces are in mills, can remove any
    if (!hasNonMillPieces) {
      for (int i = 0; i < 24; i++) {
        if (board[i] == opponent) {
          removable.add(i);
        }
      }
    }

    return removable;
  }

  // ============ AI LOGIC - ENHANCED ============
  // Difficulty-based depth limits
  static const Map<String, int> difficultyDepths = {
    'easy': 1,     // Look ahead 1 move
    'medium': 2,   // Look ahead 2 moves
    'hard': 3,     // Look ahead 3 moves
    'expert': 4,   // Look ahead 4 moves
  };

  void makeAIMove() {
    if (phase == 'placing') {
      _aiPlacePiece();
    } else if (phase == 'moving') {
      _aiMovePiece();
    } else if (phase == 'removing') {
      _aiRemovePiece();
    }
  }

  /// Evaluate board position (positive = good for AI, negative = good for opponent)
  int _evaluateBoard() {
    final opponent = aiPlayer == 1 ? 2 : 1;
    int score = 0;
    
    // 1. Piece count advantage (most important)
    score += (piecesOnBoard[aiPlayer]! - piecesOnBoard[opponent]!) * 100;
    score += (piecesLeft[aiPlayer]! - piecesLeft[opponent]!) * 50;
    
    // 2. Mill potential (two pieces in a mill line)
    int aiMillPotential = 0;
    int oppMillPotential = 0;
    for (var mill in mills) {
      int aiCount = 0;
      int oppCount = 0;
      int emptyCount = 0;
      
      for (int pos in mill) {
        if (board[pos] == aiPlayer) aiCount++;
        else if (board[pos] == opponent) oppCount++;
        else emptyCount++;
      }
      
      // Two pieces + one empty = potential mill
      if (aiCount == 2 && emptyCount == 1) aiMillPotential++;
      if (oppCount == 2 && emptyCount == 1) oppMillPotential++;
    }
    score += (aiMillPotential - oppMillPotential) * 30;
    
    // 3. Completed mills
    int aiMills = 0;
    int oppMills = 0;
    for (int i = 0; i < 24; i++) {
      if (board[i] == aiPlayer && checkMill(i)) aiMills++;
      if (board[i] == opponent && checkMill(i)) oppMills++;
    }
    score += (aiMills - oppMills) * 40;
    
    // 4. Mobility (number of possible moves)
    if (phase == 'moving') {
      int aiMobility = 0;
      int oppMobility = 0;
      for (int i = 0; i < 24; i++) {
        if (board[i] == aiPlayer) aiMobility += getValidMoves(i).length;
        if (board[i] == opponent) oppMobility += getValidMoves(i).length;
      }
      score += (aiMobility - oppMobility) * 10;
    }
    
    // 5. Strategic positions (center squares worth more)
    List<int> centerPositions = [1, 3, 5, 7, 9, 11, 13, 15];
    for (int pos in centerPositions) {
      if (board[pos] == aiPlayer) score += 5;
      if (board[pos] == opponent) score -= 5;
    }
    
    // 6. Blocking opponent's potential mills
    score += (aiMillPotential > 0 ? 15 : 0);
    score -= (oppMillPotential > 0 ? 15 : 0);
    
    return score;
  }

  /// Minimax with alpha-beta pruning for placing phase
  (int, int?) _minimaxPlace(int depth, int alpha, int beta, bool isMaximizing) {
    // Base case: reached depth limit or game over
    if (depth == 0 || checkWinCondition()) {
      return (_evaluateBoard(), null);
    }
    
    List<int> emptyPositions = [];
    for (int i = 0; i < 24; i++) {
      if (board[i] == null) emptyPositions.add(i);
    }
    
    if (emptyPositions.isEmpty) return (_evaluateBoard(), null);
    
    if (isMaximizing) {
      int maxScore = -999999;
      int? bestMove;
      
      for (int pos in emptyPositions) {
        // Simulate move
        board[pos] = aiPlayer;
        piecesLeft[aiPlayer] = piecesLeft[aiPlayer]! - 1;
        
        int score = _minimaxPlace(depth - 1, alpha, beta, false).$1;
        
        // Undo move
        board[pos] = null;
        piecesLeft[aiPlayer] = piecesLeft[aiPlayer]! + 1;
        
        if (score > maxScore) {
          maxScore = score;
          bestMove = pos;
        }
        
        alpha = max(alpha, score);
        if (beta <= alpha) break; // Alpha-beta pruning
      }
      
      return (maxScore, bestMove);
    } else {
      int minScore = 999999;
      int? bestMove;
      final opponent = aiPlayer == 1 ? 2 : 1;
      
      for (int pos in emptyPositions) {
        // Simulate opponent move
        board[pos] = opponent;
        piecesLeft[opponent] = piecesLeft[opponent]! - 1;
        
        int score = _minimaxPlace(depth - 1, alpha, beta, true).$1;
        
        // Undo move
        board[pos] = null;
        piecesLeft[opponent] = piecesLeft[opponent]! + 1;
        
        if (score < minScore) {
          minScore = score;
          bestMove = pos;
        }
        
        beta = min(beta, score);
        if (beta <= alpha) break; // Alpha-beta pruning
      }
      
      return (minScore, bestMove);
    }
  }

  void _aiPlacePiece() {
    List<int> emptyPositions = [];
    for (int i = 0; i < 24; i++) {
      if (board[i] == null) emptyPositions.add(i);
    }

    if (emptyPositions.isEmpty) return;
    
    final depth = difficultyDepths[aiDifficulty] ?? 2;

    // 1. ALWAYS try to complete a mill first (immediate win opportunity)
    for (int pos in emptyPositions) {
      board[pos] = aiPlayer;
      if (checkMill(pos)) {
        board[pos] = null;
        placePiece(pos);
        return;
      }
      board[pos] = null;
    }

    // 2. ALWAYS block opponent's immediate mill
    int opponent = aiPlayer == 1 ? 2 : 1;
    for (int pos in emptyPositions) {
      board[pos] = opponent;
      if (checkMill(pos)) {
        board[pos] = null;
        placePiece(pos);
        return;
      }
      board[pos] = null;
    }

    // 3. Use minimax for strategic placement
    var result = _minimaxPlace(depth, -999999, 999999, true);
    if (result.$2 != null) {
      placePiece(result.$2!);
      return;
    }

    // 4. Fallback: Strategic positions
    List<int> strategic = [1, 3, 5, 7, 9, 11, 13, 15];
    List<int> availableStrategic =
        emptyPositions.where((pos) => strategic.contains(pos)).toList();
    if (availableStrategic.isNotEmpty) {
      placePiece(availableStrategic[Random().nextInt(availableStrategic.length)]);
      return;
    }

    // 5. Random placement
    placePiece(emptyPositions[Random().nextInt(emptyPositions.length)]);
  }

  void _aiMovePiece() {
    List<int> aiPieces = [];
    for (int i = 0; i < 24; i++) {
      if (board[i] == aiPlayer) aiPieces.add(i);
    }

    if (aiPieces.isEmpty) return;

    int bestScore = -999999;
    int? bestFrom;
    int? bestTo;

    // 1. ALWAYS try to form a mill first
    for (int from in aiPieces) {
      List<int> moves = getValidMoves(from);
      for (int to in moves) {
        int? temp = board[from];
        board[from] = null;
        board[to] = temp;
        if (checkMill(to)) {
          board[from] = temp;
          board[to] = null;
          movePiece(from, to);
          return;
        }
        board[from] = temp;
        board[to] = null;
      }
    }

    // 2. ALWAYS block opponent's immediate mill threat
    int opponent = aiPlayer == 1 ? 2 : 1;
    for (int from in aiPieces) {
      List<int> moves = getValidMoves(from);
      for (int to in moves) {
        board[to] = opponent;
        if (checkMill(to)) {
          board[to] = null;
          movePiece(from, to);
          return;
        }
        board[to] = null;
      }
    }

    // 3. Evaluate all possible moves
    for (int from in aiPieces) {
      List<int> moves = getValidMoves(from);
      for (int to in moves) {
        // Simulate move
        int? temp = board[from];
        board[from] = null;
        board[to] = temp;
        
        int score = _evaluateBoard();
        
        // Undo move
        board[from] = temp;
        board[to] = null;
        
        if (score > bestScore) {
          bestScore = score;
          bestFrom = from;
          bestTo = to;
        }
      }
    }
    
    if (bestFrom != null && bestTo != null) {
      movePiece(bestFrom, bestTo);
      return;
    }

    // 4. Fallback: Random valid move
    for (int attempt = 0; attempt < 10; attempt++) {
      int from = aiPieces[Random().nextInt(aiPieces.length)];
      List<int> moves = getValidMoves(from);
      if (moves.isNotEmpty) {
        movePiece(from, moves[Random().nextInt(moves.length)]);
        return;
      }
    }
  }

  void _aiRemovePiece() {
    List<int> removable = getRemovablePieces();
    if (removable.isEmpty) return;
    
    int opponent = aiPlayer == 1 ? 2 : 1;
    int bestScore = -999999;
    int? bestRemove;

    // Evaluate which piece removal is best
    for (int pos in removable) {
      // Check if this piece is part of a potential mill
      int potentialMills = 0;
      for (var mill in mills) {
        if (mill.contains(pos)) {
          int oppCount = 0;
          int emptyCount = 0;
          for (int p in mill) {
            if (board[p] == opponent) oppCount++;
            if (board[p] == null) emptyCount++;
          }
          if (oppCount == 2 && emptyCount == 1) potentialMills++;
        }
      }
      
      int score = potentialMills * 50;
      
      // Center pieces are more valuable
      List<int> centerPositions = [1, 3, 5, 7, 9, 11, 13, 15];
      if (centerPositions.contains(pos)) score += 10;
      
      if (score > bestScore) {
        bestScore = score;
        bestRemove = pos;
      }
    }
    
    if (bestRemove != null) {
      removePiece(bestRemove);
    } else {
      removePiece(removable[Random().nextInt(removable.length)]);
    }
  }
}

// Helper class for undo/redo functionality (renamed to avoid conflict with game_state.dart)
class GameSnapshot {
  final List<int?> board;
  final int currentPlayer;
  final String phase;
  final Map<int, int> piecesLeft;
  final Map<int, int> piecesOnBoard;

  GameSnapshot({
    required this.board,
    required this.currentPlayer,
    required this.phase,
    required this.piecesLeft,
    required this.piecesOnBoard,
  });
}

