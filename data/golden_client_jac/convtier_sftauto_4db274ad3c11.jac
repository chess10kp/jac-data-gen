def sum_of_odd_numbers(arr: Any) -> object {
    sum = 0;
    for num in arr {
        if ((num % 2) != 0) {
            sum += num;
        }
    }
    return sum;
}



with entry {
    print(sum_of_odd_numbers([]));
}
