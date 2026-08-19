def greet(name: str, /) -> str {
    return f"Hello, {name}!";
}

with entry {
    greet("Alice");      # OK
    # greet(name="Alice"); # Error: positional-only
}
