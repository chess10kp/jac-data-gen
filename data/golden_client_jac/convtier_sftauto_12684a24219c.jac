def sum_of_squares(n: Any) -> object {
    if (n < 0) {
        return "Invalid input";
    }
    result = (n * (n + 1) * ((2 * n) + 1)) // 6;
    return result;
}



with entry {
    print(sum_of_squares(5));
    print(sum_of_squares(10));
    print(sum_of_squares(2));
}
