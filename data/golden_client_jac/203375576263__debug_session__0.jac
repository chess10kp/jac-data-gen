obj Rectangle {
    has width: float;
    has height: float;

    def area -> float {
        return self.width * self.height;
    }

    def perimeter -> float {
        return 2 * (self.width + self.height);
    }
}

with entry {
    rect = Rectangle(width=5.0, height=3.0);
    print(f"Area: {rect.area()}");
    print(f"Perimeter: {rect.perimeter()}");
}
