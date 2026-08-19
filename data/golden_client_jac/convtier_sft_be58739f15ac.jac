obj Circle {
    has radius: float;

    def area() -> float { return 3.14159 * self.radius * self.radius; }
}

with entry {
    c = Circle(radius=2.0);
    print(round(c.area(), 2));
}
