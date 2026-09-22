"""Return the result of the last operation in history."""
def repeat_last_operation(calc: dict[str, list[tuple[int, int, str, int | float]]]) -> int | float | None {
    if calc['history'] {
        return calc['history'][-1][3];
    }
}