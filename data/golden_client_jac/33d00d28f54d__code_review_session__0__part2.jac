"""Game entry point with benchmark flag parsing."""

import sys;

obj Game {
    def benchmark(rounds: int) -> None { print(f"benchmarking {rounds} rounds"); }
    def play() -> None { print("playing"); }
}

glob game = Game();

with entry {
    benchmark_mode = 0;
    for arg in sys.argv[1:] {
        if arg == "--benchmark" or arg == "-b" {
            benchmark_mode = 10;
        }
    }
    if benchmark_mode > 0 {
        game.benchmark(benchmark_mode);
    } else {
        game.play();
    }
}
