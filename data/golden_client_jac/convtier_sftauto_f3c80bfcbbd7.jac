def quick_sort(arr: Any) -> object {
    if (len(arr) <= 1) {
        return arr;
    }
    pivot = random.choice(arr);
    lesser = [
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
    return (quick_sort(lesser) + equal + quick_sort(greater));
}



with entry {
    print(quick_sort([2]));
    print(quick_sort([34]));
}
