def find_max_element(arr: Any) -> object {
    max_element = float('-inf');
    for row in arr {
        for num in row {
            if (num > max_element) {
                max_element = num;
            }
        }
    }
    return max_element;
}



with entry {
    print(find_max_element([]));
}
