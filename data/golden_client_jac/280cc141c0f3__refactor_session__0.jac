"""RL driver (synthetic): number of Collatz steps for n to reach 1."""

def collatz_steps(n: int) -> int;

impl collatz_steps {
    # >>>HOLE id="syn_collatz_steps" instruction="Implement collatz_steps(n): return how many steps the Collatz process takes to bring the positive integer n down to 1. While n > 1, if n is even set n = n // 2 else set n = 3 * n + 1, counting each step; return the count (collatz_steps(1) is 0)."
    steps = 0;
    while n > 1 {
        if n % 2 == 0 {
            n = n // 2;
        } else {
            n = 3 * n + 1;
        }
        steps += 1;
    }
    return steps;
    # <<<HOLE
}

with entry {
    for x in [1, 2, 6, 7, 27] {
        print(collatz_steps(x));
    }
}
