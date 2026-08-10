"""Shift values by swapping adjacent elements from index ind onward."""
def shift(lis: list[int], ind: int) -> list[int] {
    for index in range(ind, len(lis) - 1) {
        (lis[index], lis[index + 1]) = (lis[index + 1], lis[index]);
    }
    return lis;
}