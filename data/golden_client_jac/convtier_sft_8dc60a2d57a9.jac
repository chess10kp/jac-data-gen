obj Accumulator {
    has items: list[float] = [];

    def add(x: float) -> None { self.items.append(x); }

    def mean() -> float { return sum(self.items) / len(self.items); }
}

with entry {
    acc = Accumulator();
    acc.add(10.0);
    acc.add(20.0);
    acc.add(30.0);
    print(acc.mean());
}
