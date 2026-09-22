"""Returns tuple of lines from the recursive list of tuples (item, [sub-items-tuples])."""
def delist[T](l: list[tuple[T, list[tuple[T, list]]]], result: list[T] | None = None) -> tuple[T, ...] {
    if not result {
        result = [];
    }
    for (line, sub) in l {
        result.append(line);
        delist(sub, result=result);
    }
    return tuple(result);
}