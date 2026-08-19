"""RL driver (synthetic): absolute value of an integer without the abs() builtin."""

def abs_val(n: int) -> int;

impl abs_val {
    # >>>HOLE id="syn_abs_val" instruction="Implement abs_val(n): return the absolute value of the integer n WITHOUT using the abs() builtin — return -n when n is negative, otherwise return n."
    if n < 0 {
        return -n;
    }
    return n;
    # <<<HOLE
}

with entry {
    for x in [5, -5, 0, -123, 42] {
        print(abs_val(x));
    }
}
