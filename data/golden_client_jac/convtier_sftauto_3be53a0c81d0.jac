def convert_to_roman(num: Any) -> object {
    roman_dict = {
        1: 'I',
        4: 'IV',
        5: 'V',
        9: 'IX',
        10: 'X',
        40: 'XL',
        50: 'L',
        90: 'XC',
        100: 'C',
        400: 'CD',
        500: 'D',
        900: 'CM',
        1000: 'M'
    };
    result = '';
    for (value, roman) in sorted(roman_dict.items(), reverse=True) {
        while (num >= value) {
            result += roman;
            num -= value;
        }
    }
    return result;
}



with entry {
    print(convert_to_roman(5));
    print(convert_to_roman(10));
    print(convert_to_roman(2));
}
