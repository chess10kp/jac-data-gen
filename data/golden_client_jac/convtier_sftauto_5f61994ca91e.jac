def quicksort(arr: Any) -> object {
    if (len(arr) <= 1) {
        return arr;
    }
    pivot = arr[0];
    equal = [
        x
        for x in arr
        if (x == pivot)
    ];
    lesser = [
        x
        for x in arr
        if (x < pivot)
    ];
    greater = [
        x
        for x in arr
        if (x > pivot)
    ];
    return (quicksort(lesser) + equal + quicksort(greater));
}



with entry {
    print(quicksort([81]));
    print(quicksort([]));
    print(quicksort(['a']));
}
