def quick_sort(arr: Any) -> object {
    if (len(arr) <= 1) {
        return arr;
    } else {
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
        return (quick_sort(smaller) + [pivot] + quick_sort(greater));
    }
}



with entry {
    print(quick_sort([]));
}
