def sum_of_squares(n: Any) -> object {
    total = 0;
    for i in range(1, (n + 1)) {
        if ((i % 3) != 0) {
            total += i ** 2;
        }
    }
    return total;
}



with entry {
    print(sum_of_squares(5));
    print(sum_of_squares(10));
    print(sum_of_squares(2));
}
