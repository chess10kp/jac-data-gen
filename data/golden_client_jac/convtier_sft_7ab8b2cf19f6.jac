obj BenchRow {
    has label: str;
    has avg: float = 0.0;
    has peak: float = 0.0;
    has frames: int = 0;
    has missing: bool = False;

    def one_dp(x: float) -> str {
        return str(int(x * 10.0 + 0.5) / 10.0);
    }

    def render() -> str {
        if self.missing {
            return "  " + self.label.ljust(6) + "n/a".rjust(14) + "n/a".rjust(14) + "n/a".rjust(12);
        }
        return "  " + self.label.ljust(6) + self.one_dp(self.avg).rjust(14)
            + self.one_dp(self.peak).rjust(14) + str(self.frames).rjust(12);
    }
}

def fmt_bench_row(d: dict) -> str {
    if d.get("avg") is None {
        return BenchRow(label=d["label"], missing=True).render();
    }
    return BenchRow(label=d["label"], avg=float(d["avg"]),
                    peak=float(d["max"]), frames=d["frames"]).render();
}

with entry {
    print(fmt_bench_row({'label': 'cpu', 'avg': 3.27, 'max': 9.81, 'frames': 600}));
}
