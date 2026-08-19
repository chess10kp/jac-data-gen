def quicksort(arr: Any) -> object {
    if (len(arr) <= 1) {
        return arr;
    } else {
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
        return (quicksort(smaller) + equal + quicksort(larger));
    }
}



with entry {
    print(quicksort([]));
}
