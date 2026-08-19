"""RL driver (synthetic): nth Fibonacci number (0-indexed, fib(0)=0, fib(1)=1)."""

def fibonacci(n: int) -> int;

impl fibonacci {
    # >>>HOLE id="syn_fibonacci" instruction="Implement fibonacci(n): return the nth Fibonacci number, 0-indexed with fib(0)=0 and fib(1)=1. Start a=0, b=1, and n times replace (a, b) with (b, a+b) using a temporary, then return a."
    a = 0;
    b = 1;
    i = 0;
    while i < n {
        t = a + b;
        a = b;
        b = t;
        i += 1;
    }
    return a;
    # <<<HOLE
}

with entry {
    for x in [0, 1, 2, 10, 20] {
        print(fibonacci(x));
    }
}
