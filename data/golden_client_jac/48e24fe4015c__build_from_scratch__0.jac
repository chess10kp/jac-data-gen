obj Calculator {
    has value: int = 0;

    def add(n: int) -> int {
        self.value += n;
        return self.value;
    }
}

with entry {
    calc = Calculator();
    calc.add(5);
    calc.add(3);
    print(calc.value);  # 8
}
