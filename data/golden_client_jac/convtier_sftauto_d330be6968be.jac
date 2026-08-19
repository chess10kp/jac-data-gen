def find_minimum_positive_odd(arr: Any) -> object {
    min_odd = float('inf');
    found_odd = False;
    for num in arr {
        if ((num > 0) and ((num % 2) != 0)) {
            if (num < min_odd) {
                min_odd = num;
            }
            found_odd = True;
        }
    }
    if not found_odd {
        return -1;
    } else {
        return min_odd;
    }
}



with entry {
    print(find_minimum_positive_odd([23, 7, 2]));
    print(find_minimum_positive_odd([34, 34]));
    print(find_minimum_positive_odd([4, 2, 7, 1, 9]));
}
