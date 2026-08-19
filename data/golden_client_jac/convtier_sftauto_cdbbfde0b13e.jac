def calculate_running_average_divisible_by_3(arr: Any) -> object {
    sum_divisible_by_3 = 0;
    count_divisible_by_3 = 0;
    for num in arr {
        if ((num % 3) == 0) {
            sum_divisible_by_3 += num;
            count_divisible_by_3 += 1;
        }
    }
    if (count_divisible_by_3 == 0) {
        return 0;
    }
    return (sum_divisible_by_3 / count_divisible_by_3);
}



with entry {
    print(calculate_running_average_divisible_by_3([]));
}
