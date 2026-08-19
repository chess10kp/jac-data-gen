"""RL driver (pure-lib): bench._fmt_row (padded benchmark table row).

Origin: this_is_jac/raylib_shooter/bench.jac (the `_fmt_row` formatter — one
left-justified label + three right-justified columns, or an all-'n/a' row when the
result is None). The `_one_dp` helper and a minimal `BenchResult` are provided
un-holed so the marked body is the only unit the policy regenerates. Deterministic:
pure string padding. The `with entry` block exercises both branches and prints a
deterministic projection.
"""

obj BenchResult {
    has avg: float, max: float, frames: int;
}

def _one_dp(x: float) -> str {
    return str(int(x * 10.0 + 0.5) / 10.0);
}

def _fmt_row(label: str, d: BenchResult | None) -> str {
    # >>>HOLE id="lib_fmt_row" instruction="Implement _fmt_row(label, d): if d is None, return two spaces + label left-justified to width 6 + 'n/a' right-justified to 14 + 'n/a' right-justified to 14 + 'n/a' right-justified to 12. Otherwise return two spaces + label.ljust(6) + _one_dp(d.avg).rjust(14) + _one_dp(d.max).rjust(14) + str(d.frames).rjust(12)."
    if d is None {
        return "  " + label.ljust(6) + "n/a".rjust(14) + "n/a".rjust(14) + "n/a".rjust(12);
    }
    return "  " + label.ljust(6) + _one_dp(d.avg).rjust(14) + _one_dp(d.max).rjust(14) + str(d.frames).rjust(12);
    # <<<HOLE
}

with entry {
    print(_fmt_row("cpu", BenchResult(avg=12.34, max=20.0, frames=480)));
    print(_fmt_row("gpu", BenchResult(avg=4.0, max=8.5, frames=512)));
    print(_fmt_row("io", None));
}
