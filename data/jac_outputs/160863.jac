"""
Divide and conquer sorting algorithm
that is in place and not stable.
O(n log n) time and O(log n) space in
the average case
"""
def quick_sort(array: list[int], low: int = 0, high: int | None = None) -> list[int] {
    def partition(low: int, high: int) -> int {
        pivot = low;
        left = pivot + 1;
        right = high;
        while right > left {
            while left < len(array) - 1 and array[left] < array[pivot] {
                left += 1;
            }
            while right > 0 and array[right] > array[pivot] {
                right -= 1;
            }
            if left < len(array) - 1 and right > 0 {
                (array[left], array[right]) = (array[right], array[left]);
                break;
            }
        }
        if left < len(array) and right > 0 {
            (array[pivot], array[left]) = (array[left], array[pivot]);
        }
        return left;
    }
    if high is None {
        high = len(array) - 1;
    }
    if high - low < 2 {
        return array;
    }
    pivot = partition(low, high);
    print(f"pivot is now {pivot}");
    quick_sort(array, low, pivot - 1);
    quick_sort(array, pivot, high);
    return array;
}