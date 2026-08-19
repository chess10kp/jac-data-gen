def count_divisible_greater_than_10(arr: Any) -> object {
    count = 0;
    for row in arr {
        for element in row {
            if (((element % 2) == 0) and (element > 10)) {
                count += 1;
            }
        }
    }
    return count;
}



with entry {
    print(count_divisible_greater_than_10([]));
}
