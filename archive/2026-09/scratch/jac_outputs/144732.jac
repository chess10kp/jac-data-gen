"""If at max loop size, returns loop size -1."""
def previous_number_in_loop(start: int, loop_size: int) -> int {
    return loop_size - 1 if start - 1 < 0 else start - 1;
}