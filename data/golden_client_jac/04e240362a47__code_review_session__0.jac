"""Sliding-piece move generation."""

enum Color { WHITE, BLACK }

obj Move {
    has from_pos: tuple[int, int],
        to_pos: tuple[int, int];
}

obj Board {
    has squares: list[list[Piece | None]] = [];
    def valid_pos(r: int, c: int) -> bool { return 0 <= r < 8 and 0 <= c < 8; }
    def at(r: int, c: int) -> Piece | None { return self.squares[r][c]; }
}

obj Piece {
    has color: Color,
        pos: tuple[int, int];

    def row() -> int { return self.pos[0]; }
    def col() -> int { return self.pos[1]; }

    def slide_moves(board: Board, directions: list[tuple[int, int]]) -> list[Move] {
        moves: list[Move] = [];
        for (dr, dc) in directions {
            r = self.row() + dr;
            c = self.col() + dc;
            while board.valid_pos(r, c) {
                target: Piece | None = board.at(r, c);
                if target is None {
                    moves.append(Move(from_pos=self.pos, to_pos=(r, c)));
                } elif target.color != self.color {
                    moves.append(Move(from_pos=self.pos, to_pos=(r, c)));
                    break;
                } else {
                    break;
                }
                r += dr;
                c += dc;
            }
        }
        return moves;
    }
}
