"""Convert days, hours, minutes, and seconds to total seconds."""
def make_seconds(days: int, hours: int, minutes: int, seconds: int) -> int {
    return seconds + 60 * minutes + 60 * 60 * hours + 24 * 60 * 60 * days;
}