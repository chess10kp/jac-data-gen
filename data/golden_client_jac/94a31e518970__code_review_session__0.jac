def greet(name: str, /) -> str {
    if not name {
        return "Hello, there!";
    }
    return f"Hello, {name}!";
}

with entry {
    print(greet("Alice"));      # OK
}
