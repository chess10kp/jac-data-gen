glob BOARD_SIZE: int = 8;
glob CENTER_MASK: int = 0b00111100;

enum PieceKind { PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING }
enum Color { WHITE, BLACK }

glob PIECE_VALUES: dict[PieceKind, int] = {
    PieceKind.PAWN: 100,
    PieceKind.KNIGHT: 320,
    PieceKind.BISHOP: 330,
    PieceKind.ROOK: 500,
    PieceKind.QUEEN: 900,
    PieceKind.KING: 20000
};

obj Piece {
    has kind: PieceKind;
    has color: Color;
    has has_moved: bool = False;
}

node Board {
    has squares: list[list[Piece | None]] = [];

    def evaluate(color: Color) -> int {
        score = 0;
        for r in range(BOARD_SIZE) {
            for c in range(BOARD_SIZE) {
                piece: Piece | None = self.squares[r][c];
                if piece is not None {
                    base = PIECE_VALUES[piece.kind];
                    center_bonus = 0;
                    if (1 << c & CENTER_MASK) != 0 and 2 <= r and r <= 5 {
                        center_bonus = base // 10;
                    }
                    is_minor = piece.kind == PieceKind.KNIGHT or piece.kind == PieceKind.BISHOP;
                    dev_bonus = 8 if piece.has_moved and is_minor else 0;
                    total = base + center_bonus + dev_bonus;
                    if piece.color == color {
                        score += total;
                    } else {
                        score -= total;
                    }
                }
            }
        }
        return score;
    }
}
