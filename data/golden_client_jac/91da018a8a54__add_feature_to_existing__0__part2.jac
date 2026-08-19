def example() -> int {
    x = 42;
    name = "Alice";

    count: int = 0;
    items: list[str] = [];

    # New: an explicitly-typed dict and optional
    scores: dict[str, int] = {"a": 1};
    maybe: int | None = None;

    items.append(name);
    return x + scores["a"] + count;
}

with entry {
    print(example());
}
