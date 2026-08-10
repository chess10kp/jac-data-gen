"""Move point by it velocity."""
def move_point(point: dict[str, list[float]]) -> dict[str, list[float]] {
    for (index, change) in enumerate(point['velocity']) {
        point['position'][index] += change;
    }
    return point;
}