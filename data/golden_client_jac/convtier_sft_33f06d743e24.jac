obj RunningStats {
    has lo: int = 2147483647;
    has hi: int = -2147483648;

    def add(x: int) -> None {
        if x < self.lo { self.lo = x; }
        if x > self.hi { self.hi = x; }
    }
}

with entry {
    rs = RunningStats();
    rs.add(5);
    rs.add(2);
    rs.add(8);
    print(rs.lo);
    print(rs.hi);
}
