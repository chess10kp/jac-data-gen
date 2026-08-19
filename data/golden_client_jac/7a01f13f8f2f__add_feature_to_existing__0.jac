def example() -> None {
    n = 42;
    pi = 3.14159265;

    f"{n:d}";
    f"{n:b}";
    f"{n:o}";
    f"{n:x}";
    f"{n:X}";
    f"{n:05d}";

    f"{pi:f}";
    f"{pi:.2f}";
    f"{pi:10.2f}";
    f"{pi:e}";
    f"{pi:.2e}";
    f"{pi:g}";

    ratio = 0.756;
    f"{ratio:.1%}";

    big = 1234567;
    f"{big:,}";
    f"{big:_}";

    # New: print a currency-style formatted total
    total = 1999.5;
    print(f"Total: ${total:,.2f}");
}

with entry {
    example();
}
