def count_odd_greater_than_10_divisible_by_3(arr: Any) -> object {
    count = 0;
    for num in arr {
        if ((num > 10) and ((num % 3) == 0) and ((num % 2) != 0)) {
            count += 1;
        }
    }
    return count;
}



with entry {
    print(count_odd_greater_than_10_divisible_by_3([]));
}
