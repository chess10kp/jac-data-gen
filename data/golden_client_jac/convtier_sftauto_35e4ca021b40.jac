def quicksort_descending(arr: Any) -> object {
    if (len(arr) <= 1) {
        return arr;
    }
    pivot = arr[-1];
    less_than_pivot = [];
    greater_than_pivot = [];
    for i in range((len(arr) - 1)) {
        if (arr[i] <= pivot) {
            less_than_pivot.append(arr[i]);
        } else {
            greater_than_pivot.append(arr[i]);
        }
    }
    sorted_less = quicksort_descending(less_than_pivot);
    sorted_greater = quicksort_descending(greater_than_pivot);
    return (sorted_greater + [pivot] + sorted_less);
}



with entry {
    print(quicksort_descending([]));
}
