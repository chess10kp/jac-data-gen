obj Calculator {
    has value: int = 0;
    def add(n: int) -> int;
    def reset() -> None;
}

impl Calculator.add(n: int) -> int {
    self.value += n;
    return self.value;
}

impl Calculator.reset() -> None {
    self.value = 0;
}

with entry {
    calc = Calculator();
    calc.add(5);
    calc.add(3);
    print(calc.value);
}
