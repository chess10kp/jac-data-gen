import math;

obj Vector2D {
    has x: float;
    has y: float;

    def add(other: Vector2D) -> Vector2D {
        return Vector2D(x=self.x + other.x, y=self.y + other.y);
    }

    def magnitude() -> float {
        return math.sqrt(self.x ** 2 + self.y ** 2);
    }
}

with entry {
    v = Vector2D(x=1.0, y=2.0).add(Vector2D(x=3.0, y=4.0));
    print(round(v.magnitude(), 2));
}
