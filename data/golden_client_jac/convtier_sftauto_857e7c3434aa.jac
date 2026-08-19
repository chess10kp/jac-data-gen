def quicksort(arr: Any) -> object {
    if (len(arr) <= 1) {
        return arr;
    }
    pivot = arr[0];
    smaller = [
        x
        for x in arr[1:]
        if (x <= pivot)
    ];
    greater = [
        x
        for x in arr[1:]
        if (x > pivot)
    ];
    return (quicksort(smaller) + [pivot] + quicksort(greater));
}



with entry {
    print(quicksort([2]));
    print(quicksort([34]));
}
