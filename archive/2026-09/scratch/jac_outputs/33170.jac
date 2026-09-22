"""
In this algorithm, we want to find whether element x belongs to a set of numbers stored in an array numbers[]. Where l and r represent the left and right index of a sub-array in which searching operation should be performed.
"""
def maf_binary(sorted_array: list[int], value: int) -> int | None {
    min = 0;
    max = len(sorted_array) - 1;
    while min <= max {
        mid = (min + max) // 2;
        if sorted_array[mid] > value {
            max = mid - 1;
        } elif sorted_array[mid] < value {
            min = mid + 1;
        } else {
            return mid;
        }
    }
}