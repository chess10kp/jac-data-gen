obj RunningStats {
    has n: int = 0;
    has mean: float = 0.0;
    has m2: float = 0.0;

    def add(x: float) -> None {
        self.n += 1;
        delta = x - self.mean;
        self.mean += delta / self.n;
        self.m2 += delta * (x - self.mean);
    }

    def variance -> float {
        return self.m2 / self.n if self.n else 0.0;
    }

    def snapshot -> list {
        return [self.n, round(self.mean, 3), round(self.variance(), 3)];
    }
}

def running_stats(values: list) -> list {
    rs = RunningStats();
    for x in values {
        rs.add(x);
    }
    return rs.snapshot();
}

with entry {
    print(running_stats([2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0]));
}
