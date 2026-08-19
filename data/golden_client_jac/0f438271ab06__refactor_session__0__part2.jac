obj Greeter {
    static def greet(name: str) -> None {
        print(f"Hello, {name}!");
    }
    static def add(x: int, y: int) -> int {
        return x + y;
    }
    static def greet_default(name: str = "friend") -> None {
        print(f"Hello, {name}!");
    }
}
with entry {
    Greeter.greet("Alice");
    result = Greeter.add(5, 3);
    print(f"5 + 3 = {result}");
    Greeter.greet_default();
    Greeter.greet_default("Bob");
}
