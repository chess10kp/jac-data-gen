obj Calculator {
    has total: float = 0.0;

    def add(value: float) -> float {
        self.total += value;
        return self.total;
    }

    def reset() -> None {
        self.total = 0.0;
    }
}
