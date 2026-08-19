def find_max_divisible_by_three(arr: Any) -> object {
    max_value = -1;
    for num in arr {
        if ((num % 3) == 0) {
            if (num > max_value) {
                max_value = num;
            }
        }
    }
    return max_value if (max_value != -1) else -1;
}



with entry {
    print(find_max_divisible_by_three([]));
    print(find_max_divisible_by_three([-12, 6]));
    print(find_max_divisible_by_three([-12, -6, -3, 21]));
}
