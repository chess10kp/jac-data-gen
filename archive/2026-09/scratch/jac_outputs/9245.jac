"""The numpy sort is inconistent with the matlab version for values that
    are the same
    """
def _argsort(seq: list[float]) -> list[int] {
    return sorted(range(len(seq)), key=seq.__getitem__);
}