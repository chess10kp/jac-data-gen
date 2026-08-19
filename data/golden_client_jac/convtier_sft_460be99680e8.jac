obj Circle {
    has r: float = 0.0;
    has pi: float = 3.14159;

    def area -> float {
        return round(self.pi * self.r * self.r, 2);
    }

    def circumference -> float {
        return round(2.0 * self.pi * self.r, 2);
    }
}

def circle_metrics(r: float) -> list {
    c = Circle(r=r);
    return [c.area(), c.circumference()];
}

with entry {
    print(circle_metrics(1.5));
}
