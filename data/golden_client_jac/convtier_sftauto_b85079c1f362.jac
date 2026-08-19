def count_divisible_by_2(arr: Any) -> object {
    count = 0;
    for row in arr {
        for element in row {
            if ((element % 2) == 0) {
                count += 1;
            }
        }
    }
    return count;
}



with entry {
    print(count_divisible_by_2([]));
}
