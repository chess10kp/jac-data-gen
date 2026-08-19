def example() -> None {
    text = "hello\nworld";

    f"{text}";
    f"{text!s}";
    f"{text!r}";
    f"{text!a}";

    # New: print the repr conversion so escapes are visible
    print(f"repr -> {text!r}");
}

with entry {
    example();
}
