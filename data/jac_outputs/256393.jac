"""Return a the sum of a list of numbers, minus the min and max values"""
def sum_array(arr: list[int] | list[float]) -> int | float {
    if arr and len(arr) > 1 {
        return sum(sorted(arr)[1:-1]);
    }
    return 0;
}