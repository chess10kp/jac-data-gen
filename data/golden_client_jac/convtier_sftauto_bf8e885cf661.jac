def find_minimum(arr: Any) -> object {
    if (len(arr) == 0) {
        return None;
    }
    minimum = arr[0];
    for num in arr {
        if (num < minimum) {
            minimum = num;
        }
    }
    return minimum;
}



with entry {
    print(find_minimum('hello'));
    print(find_minimum('Racecar'));
    print(find_minimum('abcabc'));
}
