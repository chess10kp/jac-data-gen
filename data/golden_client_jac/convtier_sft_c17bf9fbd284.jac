import math;

obj Point3D {
    has x: float;
    has y: float;
    has z: float;

    def distance(other: Point3D) -> float {
        return math.sqrt(
            (self.x - other.x) ** 2 + (self.y - other.y) ** 2 + (self.z - other.z) ** 2
        );
    }
}

with entry {
    p = Point3D(x=0.0, y=0.0, z=0.0);
    q = Point3D(x=1.0, y=2.0, z=2.0);
    print(p.distance(q));
}
