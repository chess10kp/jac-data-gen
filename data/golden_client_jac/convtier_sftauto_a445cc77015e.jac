def compute_sum_of_squares(n: Any) -> object {
    sum = 0;
    for i in range((n + 1)) {
        if ((i % 2) == 0) {
            sum += i ** 2;
        }
    }
    return sum;
}



with entry {
    print(compute_sum_of_squares(5));
    print(compute_sum_of_squares(10));
    print(compute_sum_of_squares(2));
}
