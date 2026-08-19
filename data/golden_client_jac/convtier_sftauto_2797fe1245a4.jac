def check_sorted(arr: Any) -> object {
    pairs = zip(arr, arr[1:]);
    ascending = all((a <= b) for (a, b) in pairs);
    if ascending {
        return True;
    } else {
        for (i, (a, b)) in enumerate(zip(arr, arr[1:])) {
            if (a > b) {
                return (False, (i + 1));
            }
        }
    }
}



with entry {
    print(check_sorted([1, 2, 4]));
}
