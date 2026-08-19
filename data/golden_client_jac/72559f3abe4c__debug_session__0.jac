"""RL driver (pure-lib): bench._one_dp (one-decimal string, no round()).

Origin: this_is_jac/raylib_shooter/bench.jac (the `_one_dp` formatter, which
rounds to one decimal place WITHOUT the `round` builtin — its 2-arg overload trips
`jac check`). Deterministic: pure float arithmetic then stringify. The marked body
is the unit the policy must regenerate; the `with entry` block exercises it on
fixed inputs and prints a deterministic projection.
"""

def _one_dp(x: float) -> str {
    return str(int(x * 10.0 + 0.5) / 10.0);
}

with entry {
    for x in [0.0, 1.04, 1.05, 2.349, 9.96, 12.5] {
        print(_one_dp(x));
    }
}
