def digit_sum(n: Any) -> object {
    if (n == 0) {
        return 0;
    } else {
        return ((n % 10) + digit_sum((n // 10)));
    }
}



with entry {
    print(digit_sum(0));
}
