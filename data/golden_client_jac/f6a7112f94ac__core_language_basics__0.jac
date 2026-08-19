obj Calculator {
    has memory: float = 0;

    """Add to memory."""
    def add(x: float) -> float {
        self.memory += x;
        return self.memory;
    }

    """Subtract from memory."""
    def subtract(x: float) -> float {
        self.memory -= x;
        return self.memory;
    }

    """Clear memory."""
    def clear() -> float {
        self.memory = 0;
        return self.memory;
    }

    """Get current memory value."""
    def get_memory() -> float {
        return self.memory;
    }

    def calculate(instructions: str) -> str by llm(
        tools=[self.add, self.subtract, self.clear, self.get_memory]
    );
}
sem Calculator.calculate = "Perform calculations step by step.";

with entry {
    calc = Calculator();
    result = calc.calculate("Start at 0, add 10, subtract 3, then add 5");
    print(result);
    print(f"Final memory: {calc.memory}");
}
