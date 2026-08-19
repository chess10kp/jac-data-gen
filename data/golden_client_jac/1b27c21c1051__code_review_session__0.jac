"""Bishop and rook moves via shared direction constants."""

enum Color { WHITE, BLACK }

glob DIAGONALS: list[tuple[int, int]] = [(-1, -1), (-1, 1), (1, -1), (1, 1)];
glob ORTHOGONALS: list[tuple[int, int]] = [(-1, 0), (1, 0), (0, -1), (0, 1)];

obj Move {
    has from_pos: tuple[int, int],
        to_pos: tuple[int, int];
}

obj Board { has squares: list = []; }

obj Piece {
    has color: Color,
        pos: tuple[int, int];
    def slide_moves(board: Board, directions: list[tuple[int, int]]) -> list[Move] { return []; }
}

obj Bishop(Piece) {
    def raw_moves(board: Board) -> list[Move] {
        return self.slide_moves(board, DIAGONALS);
    }
}

obj Rook(Piece) {
    def raw_moves(board: Board) -> list[Move] {
        return self.slide_moves(board, ORTHOGONALS);
    }
}
