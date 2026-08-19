"""Board postinit that allocates the grid and places pieces."""

glob BOARD_SIZE: int = 8;

obj Piece { has color: int = 0; }

obj Board {
    has squares: list[list[Piece | None]] by postinit;

    def postinit {
        self.squares = [[None for _ in range(BOARD_SIZE)] for _ in range(BOARD_SIZE)];
        self.setup_pieces();
    }

    def setup_pieces() -> None {
        return;
    }
}

with entry {
    b = Board();
    print(len(b.squares));
}
