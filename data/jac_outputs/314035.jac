"""Normalize the start and end of an array by counting from the end (just like Python)."""
def startEnd(length: int, start: int, end: int) -> tuple[int, int] {
    if start >= 0 {
        norm_start = start;
    } else {
        norm_start = length + start;
    }
    if norm_start < 0 { norm_start = 0; }
    if norm_start > length { norm_start = length; }
    if end >= 0 {
        norm_end = end;
    } else {
        norm_end = length + end;
    }
    if norm_end < 0 { norm_end = 0; }
    if norm_end > length { norm_end = length; }
    if norm_end < norm_start { norm_end = norm_start; }
    return (norm_start, norm_end);
}