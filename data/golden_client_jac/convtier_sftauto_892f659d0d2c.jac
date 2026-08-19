def quicksort(arr: Any) -> object {
    if (len(arr) <= 1) {
        return arr;
    }
    pivot = random.choice(arr);
    (left, right) = partition(arr, pivot);
    return (quicksort(left) + quicksort(right));
}



with entry {
    print(quicksort([81]));
    print(quicksort([]));
    print(quicksort(['a']));
}
