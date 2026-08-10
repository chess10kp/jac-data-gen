"""Count periods between unix timestamps; start is excluded, end is included."""
def count_periods(start: int, end: int, period_length: int) -> int {
    return (int(end) - int(start)) // period_length;
}