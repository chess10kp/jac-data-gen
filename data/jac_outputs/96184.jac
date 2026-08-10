def justify_to_point(point: float, itemsize: float, just: float = 0.0) -> float {
    return point - itemsize * just;
}