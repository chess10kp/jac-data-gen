def quicksort(arr: Any) -> object {
    if (len(arr) <= 1) {
        return arr;
    } else {
        pivot = arr[0];
        lesser = [
            x
            for x in arr[1:]
            if (x <= pivot)
        ];
        greater = [
            x
            for x in arr[1:]
            if (x > pivot)
        ];
        return (quicksort(lesser) + ([pivot] * arr.count(pivot)) + quicksort(greater));
    }
}



with entry {
    print(quicksort([]));
}
