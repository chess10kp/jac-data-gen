"""Rounds an integer value up to a multiple specified."""
def _round_up_to_multiple(value: int, multiple: int) -> int {
    mod = value % multiple;
    if mod == 0 {
        return value;
    }
    return (value - mod) + multiple;
}