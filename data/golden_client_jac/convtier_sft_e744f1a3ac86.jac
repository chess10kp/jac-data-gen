obj Histogram {
    has bins: dict[str, int] = {};

    def add(label: str) -> None {
        self.bins[label] = self.bins.get(label, 0) + 1;
    }

    def count(label: str) -> int { return self.bins.get(label, 0); }
}

with entry {
    h = Histogram();
    h.add("a");
    h.add("b");
    h.add("a");
    print(h.count("a"));
}
