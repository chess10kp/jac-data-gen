def quick_sort(arr: Any) -> object {
    if (len(arr) <= 1) {
        return arr;
    }
    pivot = arr[(len(arr) // 2)];
    (smaller, equal, larger) = ([], [], []);
    for num in arr {
        if (num < pivot) {
            smaller.append(num);
        } elif (num == pivot) {
            equal.append(num);
        } else {
            larger.append(num);
        }
    }
    return (quick_sort(smaller) + equal + quick_sort(larger));
}



with entry {
    print(quick_sort([2]));
    print(quick_sort([34]));
}
