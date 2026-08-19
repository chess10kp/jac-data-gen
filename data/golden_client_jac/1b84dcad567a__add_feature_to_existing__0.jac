obj Example {
    has name: str;
    has count: int = 0;
    has items: list[str] = [];
    has mapping: dict[str, int] = {};
    has tags: set[str] = set();  # New typed field with default
}

with entry {
    e = Example(name="demo");
    e.items.append("x");
    e.tags.add("urgent");
    print(f"{e.name}: {e.items}, tags={len(e.tags)}");
}
