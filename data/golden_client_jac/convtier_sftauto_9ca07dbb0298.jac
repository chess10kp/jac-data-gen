def quicksort(arr: Any) -> object {
    if (len(arr) <= 1) {
        return arr;
    } else {
        pivot = arr[0];
        less = [
            x
            for x in arr
            if (x < pivot)
        ];
        equal = [
            x
            for x in arr
            if (x == pivot)
        ];
        greater = [
            x
            for x in arr
            if (x > pivot)
        ];
        return (quicksort(less) + equal + quicksort(greater));
    }
}



with entry {
    print(quicksort([]));
}
