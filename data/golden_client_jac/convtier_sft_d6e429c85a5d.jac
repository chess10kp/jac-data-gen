obj Rectangle {
    has width: float;
    has height: float;

    def area() -> float { return self.width * self.height; }

    def perimeter() -> float { return 2 * (self.width + self.height); }
}

with entry {
    r = Rectangle(width=3.0, height=4.0);
    print(r.area());
    print(r.perimeter());
}
