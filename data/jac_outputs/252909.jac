"""Converts hours, mins and seconds and returns consolidated seconds."""
def hr_min_sec_to_secs(hour: int, mins: int, second: int) -> int {
    return hour * 60 * 60 + mins * 60 + second;
}