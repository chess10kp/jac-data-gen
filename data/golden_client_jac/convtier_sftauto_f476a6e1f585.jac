def find_second_largest(numbers: Any) -> object {
    if (len(numbers) < 2) {
        return None;
    }
    max_value = float('-inf');
    second_max_value = float('-inf');
    for num in numbers {
        if (num > max_value) {
            second_max_value = max_value;
            max_value = num;
        } elif ((num > second_max_value) and (num != max_value)) {
            second_max_value = num;
        }
    }
    return second_max_value;
}



with entry {
    print(find_second_largest([-10368, 1296]));
    print(find_second_largest([-10368, -1296, -126, 882]));
}
