"""Chess core: color/kind enums and piece factory helpers."""

enum Color { WHITE, BLACK }
enum PieceKind { PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING }

obj Piece {
    has kind: PieceKind,
        color: Color,
        row: int,
        col: int;
}

obj Board {
    has squares: list[list[Piece | None]] = [];
}

def opposite_color(color: Color) -> Color {
    return Color.BLACK if color == Color.WHITE else Color.WHITE;
}

def to_algebraic(pos: tuple[int, int]) -> str {
    (row, col) = pos;
    files = "abcdefgh";
    return f"{files[col]}{8 - row}";
}

def create_piece(kind: PieceKind, color: Color, row: int, col: int) -> Piece {
    return Piece(kind=kind, color=color, row=row, col=col);
}

with entry {
    p = create_piece(PieceKind.QUEEN, Color.WHITE, 0, 3);
    print(to_algebraic((p.row, p.col)), opposite_color(p.color));
}
