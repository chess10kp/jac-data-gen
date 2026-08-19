def describe_point(point: tuple) -> str {
    match point {
        case (0, 0):
            return "origin";
        case (x, 0):
            return f"on x-axis at {x}";
        case (0, y):
            return f"on y-axis at {y}";
        case (x, y):
            return f"at ({x}, {y})";
        case _:
            return "not a point";
    }
}
