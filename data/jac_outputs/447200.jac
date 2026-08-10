"""Adds two arrays element-wise; returns a new array or None if lengths differ."""
def add_arrays(arr1: list[int], arr2: list[int]) -> list[int] | None {
    if len(arr1) == len(arr2) {
        return [arr1[i] + arr2[i] for i in range(len(arr1))];
    }
    return None;
}