def has_null_coordinates(coord: list[tuple[float, float]]) -> bool {
    for (x, y) in coord {
        if x == 0.0 and y == 0.0 {
            return True;
        }
    }
    return False;
}