def flatten_divisible_by_two_and_three(lst: Any) -> object {
    flattened_list = [];
    for sublist in lst {
        for num in sublist {
            if (((num % 2) == 0) and ((num % 3) == 0)) {
                flattened_list.append(num);
            }
        }
    }
    return flattened_list;
}



with entry {
    print(flatten_divisible_by_two_and_three([]));
}
