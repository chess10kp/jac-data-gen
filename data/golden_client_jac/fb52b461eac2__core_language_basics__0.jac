def greet(name: str, greeting: str = "Hello") -> str {
    return f"{greeting}, {name}!";
}

with entry {
    print(greet("Alice"));           # Hello, Alice!
    print(greet("Bob", "Hi"));       # Hi, Bob!
}
