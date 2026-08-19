def randomized_quick_sort(arr: Any) -> object {
    if (len(arr) <= 1) {
        return arr;
    } else {
        pivot = random.choice(arr);
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
        return (randomized_quick_sort(less) + equal + randomized_quick_sort(greater));
    }
}



with entry {
    print(randomized_quick_sort([]));
}
