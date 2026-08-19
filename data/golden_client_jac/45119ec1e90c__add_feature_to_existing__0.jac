impl Game.perft(depth: int) -> int {
    if depth == 0 {
        return 1;
    }
    total = 0;
    moves: list[Move] = self.legal_moves(self.current_turn);
    for move in moves {
        self.board.make_move(move);
        total += self.perft(depth - 1);
        self.board.undo_move(move);
    }
    return total;
}
