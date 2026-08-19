enum Color { WHITE = 0, BLACK = 1 }
enum PieceKind { PAWN = 0, KNIGHT = 1, BISHOP = 2, ROOK = 3, QUEEN = 4, KING = 5 }

# Castling rights as bit flags
glob CASTLE_WK: int = 0x01,
     CASTLE_WQ: int = 0x02,
     CASTLE_BK: int = 0x04,
     CASTLE_BQ: int = 0x08;

# All rights = OR of the four flags (derived, so it can't drift)
glob CASTLE_ALL: int = CASTLE_WK | CASTLE_WQ | CASTLE_BK | CASTLE_BQ;

glob CENTER_MASK: int = 0b00111100;  # Bitmask for center files
glob BOARD_SIZE: int = 8;
