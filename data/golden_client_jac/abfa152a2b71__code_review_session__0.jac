def seed_random(seed: int) {}

obj Game {
    def play_auto() -> str {
        return "Draw";
    }

    def benchmark(num_games: int) {
        white_wins = 0;
        black_wins = 0;
        draws = 0;

        print(f"Running {num_games} games...\n");

        for i in range(num_games) {
            g = Game();
            seed_random(i * 7919 + 42);
            result = g.play_auto();

            if result == "White" {
                white_wins += 1;
                print(f"Game {i + 1}: White wins");
            } elif result == "Black" {
                black_wins += 1;
                print(f"Game {i + 1}: Black wins");
            } else {
                draws += 1;
                print(f"Game {i + 1}: Draw");
            }
        }

        print(f"\n--- Results ({num_games} games) ---");
        print(f"White wins: {white_wins}");
        print(f"Black wins: {black_wins}");
        print(f"Draws:      {draws}");
    }
}
