obj Rectangle {
    has width: float;
    has height: float;
    def area -> float;
    def perimeter -> float;
}

impl Rectangle.area {
    return self.width * self.height;
}

impl Rectangle.perimeter {
    return 2 * (self.width + self.height);
}

with entry {
    rect = Rectangle(width=5.0, height=3.0);
    print(f"Area: {rect.area()}");
    print(f"Perimeter: {rect.perimeter()}");
}
