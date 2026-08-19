obj Calculator {
    has value: float = 0.0;
    def add(x: float) -> float;
    def multiply(x: float) -> float;
}

impl Calculator.add {
    self.value += x;
    return self.value;
}

impl Calculator.multiply {
    self.value *= x;
    return self.value;
}
