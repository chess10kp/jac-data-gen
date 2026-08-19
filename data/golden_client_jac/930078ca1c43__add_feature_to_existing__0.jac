def example() -> str {
    regular = "hello\nworld";
    raw = r"no\escape";
    bytes_lit = b"binary data";
    x = 42;
    f_string = f"Value: {x}";
    multiline = """
        Multiple
        lines
    """;

    # New: build a combined report string
    return f"{raw} | {f_string} | bytes={len(bytes_lit)}";
}

with entry {
    print(example());
}
