"""RL driver (pure-lib): bench._one_dp (one-decimal string, no round()).

Origin: this_is_jac/raylib_shooter/bench.jac (the `_one_dp` formatter, which
rounds to one decimal place WITHOUT the `round` builtin — its 2-arg overload trips
`jac check`). Deterministic: pure float arithmetic then stringify. The marked body
is the unit the policy must regenerate; the `with entry` block exercises it on
fixed inputs and prints a deterministic projection.
"""

def _one_dp(x: float) -> str {
    # >>>HOLE id="lib_one_dp" instruction="Implement _one_dp(x): return x rounded to one decimal place as a string WITHOUT the round() builtin — multiply x by 10.0, add 0.5, truncate to int, divide by 10.0, and stringify."
    return str(int(x * 10.0 + 0.5) / 10.0);
    # <<<HOLE
}

with entry {
    for x in [0.0, 1.04, 1.05, 2.349, 9.96, 12.5] {
        print(_one_dp(x));
    }
}
