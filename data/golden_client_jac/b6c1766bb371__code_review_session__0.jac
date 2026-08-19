enum Color { WHITE, BLACK }

obj Move {
    has to_pos: tuple[int, int];
}

node Piece {
    has color: Color;

    def attack_squares(board: Board) -> list[Move] {
        # override per piece kind; pawns attack only diagonally
        return [];
    }
}

node Board {
    def pieces_of(by_color: Color) -> list[Piece] {
        return [];
    }

    def attacked_squares(by_color: Color) -> set[tuple[int, int]] {
        attacked: set[tuple[int, int]] = set();
        for piece in self.pieces_of(by_color) {
            attacked |= {m.to_pos for m in piece.attack_squares(self)};
        }
        return attacked;
    }
}
