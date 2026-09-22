"""Create time-slices for: 22000, 18000, 14000, 10000, 6000, 2000, 1990 BP."""
def calc_delta(times: int | list[int]) -> int | list[int] {
    btime = 22000;
    if type(times) == list {
        return [(t + btime) * 12 for t in times];
    }
    return times + btime * 12;
}