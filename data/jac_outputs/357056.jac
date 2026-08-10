"""Returns a range that includes the start and end."""
def inclusive_range(start: int, end: int, stride: int = 1) -> list[int] {
    temp_range = list(range(start, end, stride));
    if end not in temp_range {
        temp_range.append(end);
    }
    return temp_range;
}