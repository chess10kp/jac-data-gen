def modified_quicksort(arr: Any) -> object {
    if (len(arr) <= 1) {
        return arr;
    }
    pivot = random.choice(arr);
    smaller = [
        x
        for x in arr
        if (x < pivot)
    ];
    equal = [
        x
        for x in arr
        if (x == pivot)
    ];
    larger = [
        x
        for x in arr
        if (x > pivot)
    ];
    return (modified_quicksort(smaller) + equal + modified_quicksort(larger));
}



with entry {
    print(modified_quicksort([]));
}
