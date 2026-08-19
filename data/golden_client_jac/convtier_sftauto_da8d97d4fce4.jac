def normalize_list(numbers: Any) -> object {
    sum_numbers = sum(numbers);
    if (sum_numbers == 10) {
        return numbers;
    } elif (sum_numbers < 10) {
        remaining = 10 - sum_numbers;
        distribution = remaining / len(numbers);
        normalized_list = [round((num + distribution)) for num in numbers];
        return normalized_list;
    } else {
        reduction_ratio = 10 / sum_numbers;
        normalized_list = [round((num * reduction_ratio)) for num in numbers];
        return normalized_list;
    }
}



with entry {
    print(normalize_list([-9]));
    print(normalize_list([10, 20]));
    print(normalize_list([-8, -4, 2, 6]));
}
