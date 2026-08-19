obj Box {
    has w: int;
    has h: int;
    has d: int;

    def volume() -> int { return self.w * self.h * self.d; }
}

with entry {
    b = Box(w=2, h=3, d=4);
    print(b.volume());
}
