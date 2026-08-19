def find_median(arr: Any) -> object {
    n = len(arr);
    if ((n % 2) == 0) {
        mid = n // 2;
        median = (arr[mid] + arr[(mid - 1)]) / 2;
    } else {
        mid = n // 2;
        median = arr[mid];
    }
    return median;
}



with entry {
    print(find_median('hello'));
    print(find_median('Racecar'));
    print(find_median('level'));
}
