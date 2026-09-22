"""([list of int], int, int) => [list of int]
    Quick sort: works by selecting a 'pivot' element from the array
    and partitioning the other elements into two sub-arrays, according
    to whether they are less than or greater than the pivot. The
    sub-arrays are then sorted recursively.

    This version will use the Hoare partition scheme, where the pivot
    is calculated in the middle instead of at the end of the list.
    "l" (for low) is the first element of the list "li", and "h" is the
    last (for high).
    """
def quick_sort_v2(li: list[int]) -> list[int] {
    def partition(lst: list[int], low: int, high: int) -> int {
        pivot = lst[(high + low) // 2];
        i = low;
        j = high - 1;
        while True {
            while lst[i] < pivot {
                i += 1;
            }
            while lst[j] > pivot {
                j -= 1;
            }
            if i >= j {
                return j;
            }
            (lst[i], lst[j]) = (lst[j], lst[i]);
        }
    }
    def sorter(li: list[int], l: int, h: int) -> list[int] {
        if l < h {
            p = partition(li, l, h);
            sorter(li, l, p);
            sorter(li, p + 1, h);
        }
        return li;
    }
    return sorter(li, 0, len(li));
}