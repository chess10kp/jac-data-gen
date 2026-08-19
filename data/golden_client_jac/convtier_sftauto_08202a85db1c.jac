def filter_and_sort(numbers: Any) -> object {
    filtered_numbers = [];
    for num in numbers {
        if (((num % 3) != 0) and ((num % 4) != 0)) {
            filtered_numbers.append(num);
        }
    }
    filtered_numbers.sort(reverse=True);
    return filtered_numbers;
}



with entry {
    print(filter_and_sort([2, 9]));
    print(filter_and_sort([34]));
    print(filter_and_sort([10, 20, 30]));
}
