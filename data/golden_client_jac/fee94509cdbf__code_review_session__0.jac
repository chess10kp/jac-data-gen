"""Piece hierarchy with an abstract move generator."""

enum Color { WHITE, BLACK }
enum PieceKind { PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING }

obj Board { has squares: list = []; }

obj Move {
    has from_pos: tuple[int, int],
        to_pos: tuple[int, int];
}

obj Piece {
    has color: Color,
        kind: PieceKind,
        pos: tuple[int, int],
        has_moved: bool = False;

    def row() -> int { return self.pos[0]; }
    def col() -> int { return self.pos[1]; }
    def set_pos(row: int, col: int) -> None { self.pos = (row, col); }
    def symbol() -> str { return "?"; }
    def raw_moves(board: Board) -> list[Move] abs;
    def slide_moves(board: Board, directions: list[tuple[int, int]]) -> list[Move] { return []; }
}

obj Pawn(Piece)   { override def raw_moves(board: Board) -> list[Move] { return []; } }
obj Knight(Piece) { override def raw_moves(board: Board) -> list[Move] { return []; } }
obj Bishop(Piece) { override def raw_moves(board: Board) -> list[Move] { return self.slide_moves(board, [(-1, -1), (-1, 1), (1, -1), (1, 1)]); } }
obj Rook(Piece)   { override def raw_moves(board: Board) -> list[Move] { return self.slide_moves(board, [(-1, 0), (1, 0), (0, -1), (0, 1)]); } }
obj Queen(Piece)  { override def raw_moves(board: Board) -> list[Move] { return []; } }
obj King(Piece)   { override def raw_moves(board: Board) -> list[Move] { return []; } }
