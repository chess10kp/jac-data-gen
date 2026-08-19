import math;

obj Point {
    has x: float;
    has y: float;

    def distance_to(other: Point) -> float {
        return math.sqrt((self.x - other.x) ** 2 + (self.y - other.y) ** 2);
    }
}

with entry {
    a = Point(x=0.0, y=0.0);
    b = Point(x=3.0, y=4.0);
    print(a.distance_to(b));
}
