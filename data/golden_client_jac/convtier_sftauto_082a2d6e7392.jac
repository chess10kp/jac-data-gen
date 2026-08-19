def sum_divisible_by_3(arr: Any) -> object {
    sum = 0;
    for num in arr {
        if (((num % 3) == 0) and (num > 5)) {
            sum += num;
        }
    }
    return sum;
}



with entry {
    print(sum_divisible_by_3([]));
}
