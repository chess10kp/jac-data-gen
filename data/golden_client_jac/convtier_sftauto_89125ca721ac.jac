def convert_float_to_string(num: Any) -> object {
    rounded_num = round(num, 3);
    if (rounded_num < 1) {
        string_num = '0' + str(rounded_num);
    } else {
        string_num = str(rounded_num);
    }
    if ((rounded_num % 2) == 0) {
        string_num += ' EVEN';
    } else {
        string_num += ' ODD';
    }
    return string_num;
}



with entry {
    print(convert_float_to_string(5));
    print(convert_float_to_string(10));
    print(convert_float_to_string(2));
}
