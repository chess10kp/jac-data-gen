"""Time Complexity : O(n). Space Complexity : O(n)."""
def union(arr1: list[int], arr2: list[int]) -> int {
    return len(set(arr1 + arr2));
}