"""Round a float to one decimal place and return it as a string, without the 2-arg round() builtin."""

def _one_dp(x: float) -> str {
    return str(int(x * 10.0 + 0.5) / 10.0);
}

with entry {
    for x in [0.0, 1.04, 1.05, 2.349, 9.96, 12.5] {
        print(_one_dp(x));
    }
}
