def find_maximum_element(arr: Any) -> object {
    max_element = float('-inf');
    for row in arr {
        for element in row {
            if (element > max_element) {
                max_element = element;
            }
        }
    }
    return max_element;
}



with entry {
    print(find_maximum_element([]));
}
