obj Calculator {
    has total: float = 0.0;

    def add(value: float) -> None {
        self.total += value;
    }

    def value() -> float {
        return self.total;
    }

    def reset() -> None {
        self.total = 0.0;
    }
}
