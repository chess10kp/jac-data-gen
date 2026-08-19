obj Circle {
    has radius: float = 1.0;
    has diameter: float {
        getter -> float { return self.radius * 2.0; }
    }
}
