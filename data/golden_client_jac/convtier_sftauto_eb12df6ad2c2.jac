def digit_sum(number: Any) -> object {
    if ((number <= 0) or (number > 100)) {
        return 0;
    }
    number = math.floor(number);
    number_str = str(number).lstrip('0');
    digit_sum = 0;
    for char in number_str {
        digit_sum += int(char);
    }
    return digit_sum;
}



with entry {
    print(digit_sum(0));
}
