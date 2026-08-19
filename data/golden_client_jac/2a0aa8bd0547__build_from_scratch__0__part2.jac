def greet(name: str) -> str {
    return f"Good morning, {name}! Let's plan your day.";
}

def add(a: int, b: int) -> int {
    return a + b;
}

with entry {
    print(greet("Alice"));
    print(add(2, 3));  # 5
}
