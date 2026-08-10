"""Bubble sort in place and return the sorted list."""
def bubble_sort(nums_array: list[int]) -> list[int] {
    is_sorted = True;
    for i in range(len(nums_array) - 1) {
        for j in range(len(nums_array) - i - 1) {
            if nums_array[j] > nums_array[j + 1] {
                is_sorted = False;
                temp = nums_array[j];
                nums_array[j] = nums_array[j + 1];
                nums_array[j + 1] = temp;
            }
        }
        if is_sorted {
            break;
        }
    }
    return nums_array;
}