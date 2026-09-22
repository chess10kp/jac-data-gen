"""Check if position is in interval. Return boolean."""
def pos_in_interval(pos: int | str, intervalstart: int | str, intervalend: int | str) -> bool {
    pos = int(pos);
    intervalstart = int(intervalstart);
    intervalend = int(intervalend);
    return pos >= intervalstart and pos <= intervalend;
}