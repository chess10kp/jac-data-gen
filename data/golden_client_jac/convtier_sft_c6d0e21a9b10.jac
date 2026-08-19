obj Interval {
    has low: int;
    has high: int;

    def contains(x: int) -> bool {
        return self.low <= x and x <= self.high;
    }
}

with entry {
    iv = Interval(low=1, high=10);
    print(iv.contains(5));
    print(iv.contains(15));
}
