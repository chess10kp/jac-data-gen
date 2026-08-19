def remove_duplicates_and_sort(lst: Any) -> object {
    numbers = [];
    for element in lst {
        if isinstance(element, (int, float)) {
            numbers.append(element);
        }
    }
    numbers = sorted(`set(numbers), reverse=True);
    return numbers;
}



with entry {
    print(remove_duplicates_and_sort('hello'));
    print(remove_duplicates_and_sort([-12, 6]));
    print(remove_duplicates_and_sort([-12, -6, -3, 21]));
}
