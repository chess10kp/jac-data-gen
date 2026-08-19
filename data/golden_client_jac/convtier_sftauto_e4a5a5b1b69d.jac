def clean_and_sort(lst: Any) -> object {
    result = [];
    for element in lst {
        if (`type(element) == int) {
            result.append((element + 5));
        }
    }
    n = len(result);
    for i in range(n) {
        for j in range(0, (n - i - 1)) {
            if (result[j] < result[(j + 1)]) {
                (result[j], result[(j + 1)]) = (result[(j + 1)], result[j]);
            }
        }
    }
    return result;
}



with entry {
    print(clean_and_sort('hello'));
    print(clean_and_sort([4, 3, 2, 1]));
    print(clean_and_sort([3, 2, 1]));
}
