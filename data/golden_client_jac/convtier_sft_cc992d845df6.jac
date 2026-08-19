obj Pair {
    has a: int;
    has b: int;

    def swapped() -> list[int] { return [self.b, self.a]; }
}

with entry {
    p = Pair(a=1, b=2);
    print(p.swapped());
}
