"""aggregation: inverse of array length"""
def group_normalized_count(arr: list[int]) -> float {
    1.0 / float(len(arr))
}