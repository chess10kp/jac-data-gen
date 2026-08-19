def greet(name: str) -> str {
    return f"Hello, {name}!";
}

def add(a: int, b: int) -> int {
    return a + b;
}

def apply(func: Callable[[int, int], int], x: int, y: int) -> int {
    return func(x, y);
}
