obj Circle {
    has radius: float;

    def circumference() -> float { return 2 * 3.14159 * self.radius; }
}

with entry {
    c = Circle(radius=1.0);
    print(round(c.circumference(), 2));
}
