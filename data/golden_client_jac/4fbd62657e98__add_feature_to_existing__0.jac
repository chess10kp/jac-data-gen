def example() -> None {
    x = 42;
    y = -42;

    f"{x:+}";
    f"{y:+}";
    f"{x:05}";

    # New: always-signed, zero-padded to width 6
    print(f"{x:+06}");
    print(f"{y:+06}");
}

with entry {
    example();
}
