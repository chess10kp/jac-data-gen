"""
    Function to achieve 2-way partitioning for quicksort
    1. Start with 2 pointers lt and gt, choose first element (lo) as pivot
    2. Invariant: everything to the left of lt is less than pivot, right of gt is larger than pivot
    3. In each iteration, do the following in order:
        (a) Increment lt until arr[lt] >= arr[lo]
        (b) Decrement gt until arr[gt] <= arr[lo]
        (c) Check if pointers have crossed (gt<=lt),
                if yes then swap arr[lo] with arr[gt] and break out
        (d) If pointers didn't cross, then swap arr[lt] with arr[gt]
    4. Return the index of the pivot (now gt) so that it can be used by __quicksortHelper__
    """
def __partition2way__(arr: list[int], lo: int, hi: int) -> int | None {
    if lo >= hi {
        return;
    }
    lt = lo;
    gt = hi + 1;
    while True {
        while lt < hi {
            lt += 1;
            if arr[lt] >= arr[lo] {
                break;
            }
        }
        while gt > lo {
            gt -= 1;
            if arr[gt] < arr[lo] {
                break;
            }
        }
        if gt <= lt {
            (arr[lo], arr[gt]) = (arr[gt], arr[lo]);
            break;
        }
        if arr[lt] > arr[gt] {
            (arr[lt], arr[gt]) = (arr[gt], arr[lt]);
        }
    }
    return gt;
}