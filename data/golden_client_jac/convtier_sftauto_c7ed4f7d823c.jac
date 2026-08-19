def sum_of_squares(n: Any) -> object {
    sum = 0;
    for i in range(1, (n + 1)) {
        sum += i * i;
    }
    return sum;
}



with entry {
    print(sum_of_squares(5));
    print(sum_of_squares(10));
    print(sum_of_squares(2));
}
