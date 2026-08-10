"""Return the total value for a combination."""
def combValue(comb: list[int], value: list[int]) -> int {
    total = 0;
    for i in comb {
        total = total + value[i];
    }
    return total;
}