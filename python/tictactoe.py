victoryStates = [
  # Horizontal
  (0, 1, 2), (3, 4, 5), (6, 7, 8),
  # Vertical
  (0, 3, 6), (1, 4, 7), (2, 5, 8),
  # Diagonal
  (0, 4, 8), (2, 4, 6),
]

PlayerX = 0
PlayerO = 1

class Player:
  def __init__(self, identifier, goal):
    self.identifier = identifier
    self.goal = goal

class Goal:
  def __init__(self, name, func):
    self.name = name
    self.evaluate = evaluate

def seekVictory(board, player):
  for i, j, k in victoryStates:
    if board[i] == board[j] == board[k] == player.identifier:
      return True
  return False

def seekDefeat(board, player):
  for i, j, k in victoryStates:
    if board[i] == board[j] == board[k] != player.identifier:
      return True
  return False

def seekStalemate(board, player):
  for i, j, k in victoryStates:
    if board[i] == board[j] == board[k] != player.identifier:
      return True
  return not any(cell is None for cell in board)

def printBoard(board):
  print("%s %s %s\n%s %s %s\n%s %s %s" % tuple(c or "_" for c in board))

def getAvailableMoves(board):
  return [i for i, cell in enumerate(board) if cell is None]

def nextPlayer(players):
  return players[1:] + [players[0]]

def makeMove(board, move, player):
  board[move] = player.identifier

def clearMove(board, move):
  board[move] = None

def isGameOver(board):
  for i, j, k in victoryStates:
    if board[i] == board[j] == board[k] != None:
      return True
  return not any(cell is None for cell in board)

def canWin(board, players):
  currentPlayer = players[0]
  for move in getAvailableMoves(board):
    makeMove(board, move, currentPlayer)
    if isGameOver(board, currentPlayer):
      clearMove(board, move)
      return 
    if not canWin(board, nextPlayer(players)):
      clearMove(board, move)
      return True
  return False


print(canWin([None] * 9, 
      [Player('X', seekVictory),
       Player('O', seekVictory)]))
