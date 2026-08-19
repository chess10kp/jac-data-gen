obj Rectangle {
    has width: float;
    has height: float;

    def area() -> float {
        return self.width * self.height;
    }

    def perimeter() -> float {
        return 2 * (self.width + self.height);
    }

    def describe() -> None {
        print(f"Rectangle: {self.width} x {self.height}");
        print(f"Area: {self.area()}");
        print(f"Perimeter: {self.perimeter()}");
    }
}

with entry {
    Rectangle(width=5.0, height=3.0).describe();
}
