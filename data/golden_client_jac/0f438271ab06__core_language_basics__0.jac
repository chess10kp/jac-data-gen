# Basic function
def greet(name: str) {
    print(f"Hello, {name}!");
}

# With return value
def add(x: int, y: int) -> int {
    return x + y;
}

# With default parameters
def greet_default(name: str = "friend") {
    print(f"Hello, {name}!");
}

with entry {
    greet("Alice");
    result = add(5, 3);
    print(f"5 + 3 = {result}");
    greet_default();
    greet_default("Bob");
}
