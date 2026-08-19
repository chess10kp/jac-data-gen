obj Counter {
    has value: int = 0;

    def inc() -> None { self.value += 1; }

    def dec() -> None { self.value -= 1; }

    def get() -> int { return self.value; }
}

with entry {
    c = Counter();
    c.inc();
    c.inc();
    c.dec();
    print(c.get());
}
