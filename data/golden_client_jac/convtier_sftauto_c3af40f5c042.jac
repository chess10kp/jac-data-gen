def calculate_sum(arr: Any) -> object {
    sum = 0;
    smallest_even = float('inf');
    for num in arr {
        if ((num > 5) and (num <= (10 ** 9)) and ((num % 2) == 0)) {
            sum += num;
            smallest_even = min(smallest_even, num);
        }
    }
    while ((sum % 7) == 0) {
        sum -= smallest_even;
    }
    return sum;
}



with entry {
    print(calculate_sum([]));
    print(calculate_sum([-12, 6]));
}
