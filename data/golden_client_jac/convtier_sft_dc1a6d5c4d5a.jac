obj Clock {
    has hour: int;

    def tick() -> None { self.hour = (self.hour + 1) % 24; }
}

with entry {
    c = Clock(hour=23);
    c.tick();
    print(c.hour);
}
