def quicksort(arr: Any) -> object {
    if (len(arr) <= 1) {
        return arr;
    }
    pivot = arr[(len(arr) // 2)];
    left = [
        x
        for x in arr
        if (x < pivot)
    ];
    right = [
        x
        for x in arr
        if (x > pivot)
    ];
    return (quicksort(left) + [pivot] + quicksort(right));
}



with entry {
    print(quicksort([81]));
    print(quicksort([]));
    print(quicksort(['a']));
}
