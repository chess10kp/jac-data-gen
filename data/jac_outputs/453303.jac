"""Return times in seconds by adding HMS offset tuples to a start time."""
def sec_from_hms(start: int | float, *times: tuple[int, ...]) -> list[int | float] {
    ret = [];
    for t in times {
        cur = 0;
        if len(t) > 0 {
            cur += t[0] * 3600;
        }
        if len(t) > 1 {
            cur += t[1] * 60;
        }
        if len(t) > 2 {
            cur += t[2];
        }
        ret.append(start + cur);
    }
    return ret;
}