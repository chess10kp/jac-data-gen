obj BBox {
    has min_x: int = 0;
    has min_y: int = 0;
    has max_x: int = 0;
    has max_y: int = 0;

    def expand(p: list) -> None {
        self.min_x = min(self.min_x, p[0]);
        self.max_x = max(self.max_x, p[0]);
        self.min_y = min(self.min_y, p[1]);
        self.max_y = max(self.max_y, p[1]);
    }

    def dims -> list {
        return [self.max_x - self.min_x, self.max_y - self.min_y];
    }
}

def bounding_box(points: list) -> list {
    box = BBox(
        min_x=points[0][0], max_x=points[0][0],
        min_y=points[0][1], max_y=points[0][1]
    );
    for p in points[1:] {
        box.expand(p);
    }
    return box.dims();
}

with entry {
    print(bounding_box([[1, 2], [4, 6], [-2, 3]]));
}
