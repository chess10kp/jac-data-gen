obj Calculator {
    has memory: float = 0.0;

    def add(x: float) -> float {
        self.memory += x;
        return self.memory;
    }

    def subtract(x: float) -> float {
        self.memory -= x;
        return self.memory;
    }

    def clear() -> float {
        self.memory = 0.0;
        return self.memory;
    }

    def calculate(instructions: str) -> str by llm(
        tools=[self.add, self.subtract, self.clear]
    );
}
