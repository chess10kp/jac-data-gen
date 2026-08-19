"""RL driver (synthetic): sum of the decimal digits of an integer."""

def digit_sum(n: int) -> int;

impl digit_sum {
    # >>>HOLE id="syn_digit_sum" instruction="Implement digit_sum(n): return the sum of the decimal digits of n (ignore sign). Take abs(n), then repeatedly add n % 10 to a running total and integer-divide n by 10 until n is 0; return the total (digit_sum(0) is 0)."
    n = abs(n);
    total = 0;
    while n > 0 {
        total += n % 10;
        n = n // 10;
    }
    return total;
    # <<<HOLE
}

with entry {
    for x in [0, 5, 42, 12345, 99999] {
        print(digit_sum(x));
    }
}
