def find_min(arr: Any) -> object {
    minimum = arr[0];
    for num in arr[1:] {
        if (num < minimum) {
            minimum = num;
        }
    }
    return minimum;
}



with entry {
    print(find_min('hello'));
    print(find_min('Racecar'));
    print(find_min('abcabc'));
}
