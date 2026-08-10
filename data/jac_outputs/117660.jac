"""Returns mean of arr."""
def mean(arr: list[int]) -> float | None {
    return sum(arr) / len(arr) if arr else None;
}