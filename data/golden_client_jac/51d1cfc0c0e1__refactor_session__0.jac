"""RL driver (synthetic): render a non-negative integer as a base-3 string."""

def base3(n: int) -> str;

impl base3 {
    # >>>HOLE id="syn_base3" instruction="Implement base3(n): return the base-3 (ternary) representation of the non-negative integer n as a string, with base3(0) == \"0\". Repeatedly prepend str(n % 3) to the result and integer-divide n by 3 until n is 0."
    if n == 0 {
        return "0";
    }
    s = "";
    while n > 0 {
        s = str(n % 3) + s;
        n = n // 3;
    }
    return s;
    # <<<HOLE
}

with entry {
    for x in [0, 1, 3, 10, 26] {
        print(base3(x));
    }
}
