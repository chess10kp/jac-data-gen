obj BenchResult {
    has avg: float, max: float, frames: int;
}

def _one_dp(x: float) -> str {
    return str(int(x * 10.0 + 0.5) / 10.0);
}

def _fmt_row(label: str, d: BenchResult | None) -> str {
    if d is None {
        return "  " + label.ljust(6) + "n/a".rjust(14) + "n/a".rjust(14) + "n/a".rjust(12);
    }
    return "  " + label.ljust(6) + _one_dp(d.avg).rjust(14) + _one_dp(d.max).rjust(14) + str(d.frames).rjust(12);
}

with entry {
    print(_fmt_row("cpu", BenchResult(avg=12.34, max=20.0, frames=480)));
    print(_fmt_row("gpu", BenchResult(avg=4.0, max=8.5, frames=512)));
    print(_fmt_row("io", None));
}
