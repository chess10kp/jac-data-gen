def filter_and_sort(numbers: Any) -> object {
    filtered_numbers = [
        num
        for num in numbers
        if (((num % 3) == 0) and ((num % 4) == 0))
    ];
    sorted_numbers = sorted(filtered_numbers, reverse=True);
    return sorted_numbers;
}



with entry {
    print(filter_and_sort([]));
}
