def change_fmt(val: int | float, fmt: Callable[[int | float], str]) -> str {
    if val > 0 {
        return "+" + fmt(val);
    }
    return fmt(val);
}