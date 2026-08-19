import math;

obj Shape {
    has name: str;
    def area -> float;
}

obj Circle(Shape) {
    has radius: float;
    override def area -> float;
}

impl Circle.area -> float {
    return math.pi * self.radius * self.radius;
}

with entry {
    print(Circle(name="c", radius=5.0).area());
}
