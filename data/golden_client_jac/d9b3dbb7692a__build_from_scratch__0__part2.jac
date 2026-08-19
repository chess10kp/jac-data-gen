"""A simple greeting module."""

def greet(name: str) -> str {
    return f"Hello, {name}!";
}

with entry {
    message = greet("World");
    print(message);
}
