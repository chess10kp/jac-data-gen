def example() -> None {
    name = "Alice";
    f"{name:10}";
    f"{name:>10}";
    f"{name:^10}";
    f"{name:<10}";

    f"{name:*>10}";
    f"{name:-^10}";

    # New: print a right-aligned column, padded to width 12
    print(f"[{name:>12}]");
}

with entry {
    example();
}
