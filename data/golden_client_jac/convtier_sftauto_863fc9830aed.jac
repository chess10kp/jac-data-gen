def format_number(number: Any) -> object {
    if (number[0] == '-') {
        sign = '-';
        number = number[1:];
    } else {
        sign = '';
    }
    formatted_number = sign + number[-3:];
    for i in range((len(number) - 3), 0, -3) {
        formatted_number = number[(i - 3):i] + ',' + formatted_number;
    }
    return formatted_number;
}



with entry {
    print(format_number('hello'));
    print(format_number('Racecar'));
    print(format_number('abcabc'));
}
