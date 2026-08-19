obj RangeSum {
    has low: int;
    has high: int;

    def total() -> int { return sum(range(self.low, self.high + 1)); }
}

with entry {
    rs = RangeSum(low=1, high=5);
    print(rs.total());
}
