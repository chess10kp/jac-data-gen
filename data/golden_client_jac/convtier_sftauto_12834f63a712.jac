def filter_odd_divisible_by_three(array: Any) -> object {
    filtered_array = [
        num
        for num in array
        if (((num % 2) == 0) and ((num % 3) != 0))
    ];
    sorted_array = sorted(filtered_array);
    return sorted_array;
}



with entry {
    print(filter_odd_divisible_by_three([]));
}
