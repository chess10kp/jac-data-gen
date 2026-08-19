def digit_sum(n: Any) -> object {
    return sum(int(digit) for digit in str(`abs(n)));
}



with entry {
    print(digit_sum(5));
    print(digit_sum(10));
    print(digit_sum(2));
}
