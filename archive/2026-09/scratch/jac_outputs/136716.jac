"""Makes x axis tick labels for `plot_time_errors` by iterating through a given array."""
def make_special_ticks(arr: list[int]) -> list[str] {
    s = "$t={} \\ \\to  \\ t={}$";
    return [s.format(i, i + 1) for i in arr];
}