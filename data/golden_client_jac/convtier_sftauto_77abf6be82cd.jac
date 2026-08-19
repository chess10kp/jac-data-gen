def calculate_digit_sum(number: Any) -> object {
    if ((number > 0) and (number <= 100)) {
        digit_sum = 0;
        while (number > 0) {
            digit_sum += number % 10;
            number //= 10;
        }
        return digit_sum;
    } else {
        return "Number should be positive and less than or equal to 100.";
    }
}



with entry {
    print(calculate_digit_sum(5));
    print(calculate_digit_sum(10));
    print(calculate_digit_sum(2));
}
