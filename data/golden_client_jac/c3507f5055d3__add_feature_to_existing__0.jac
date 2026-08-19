def example() -> None {
    width = 10;
    pi = 3.14159;

    f"{pi:{width}}";

    value = "test";
    f"{value:>10}";

    # New: dynamic precision as well as width
    precision = 2;
    print(f"[{pi:{width}.{precision}f}]");
}

with entry {
    example();
}
