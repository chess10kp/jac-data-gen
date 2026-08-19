"""RL driver (synthetic): factorial n! of a non-negative integer."""

def factorial(n: int) -> int;

impl factorial {
    # >>>HOLE id="syn_factorial" instruction="Implement factorial(n): return n! (the product 1*2*...*n) for n >= 0, with factorial(0) == 1. Start result at 1 and multiply it by every integer i from 2 up to and including n."
    result = 1;
    i = 2;
    while i <= n {
        result *= i;
        i += 1;
    }
    return result;
    # <<<HOLE
}

with entry {
    for x in [0, 1, 5, 7, 10] {
        print(factorial(x));
    }
}
