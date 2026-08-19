def unique_sorted_array(arr: Any) -> object {
    unique_elements = [];
    for num in arr {
        if (num not in unique_elements) {
            unique_elements.append(num);
        }
    }
    n = len(unique_elements);
    for i in range((n - 1)) {
        for j in range(0, (n - i - 1)) {
            if (unique_elements[j] > unique_elements[(j + 1)]) {
                (unique_elements[j], unique_elements[(j + 1)]) = (
                    unique_elements[(j + 1)],
                    unique_elements[j]
                );
            }
        }
    }
    return unique_elements;
}



with entry {
    print(unique_sorted_array('hello'));
    print(unique_sorted_array('Racecar'));
    print(unique_sorted_array('abcabc'));
}
