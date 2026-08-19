obj Rectangle {
    has width: float;
    has height: float;

    def area -> float {
        return self.width * self.height;
    }
}

with entry {
    rect = Rectangle(width=5.0, height=3.0);
    print(f"Area: {rect.area()}");
}
