def example() {
    x = 42;
    y = -42;

    f"{x:+}";               # "+42" (always show sign)
    f"{y:+}";               # "-42"
    f"{x:05}";              # "00042" (zero-padded)
}
