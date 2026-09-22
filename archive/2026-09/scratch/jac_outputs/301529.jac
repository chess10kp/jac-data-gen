""" Check if segment b is fully contained within segment a """
def is_contained(a: list[int], b: list[int]) -> bool {
    return b[0] >= a[0] and b[1] <= a[1];
}