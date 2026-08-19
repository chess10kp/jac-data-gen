def remove_leading_zeros(string: Any) -> object {
    if string.startswith('0') {
        i = 0;
        while (
            (i < (len(string) - 1))
            and (string[i] == '0')
            and not string[(i + 1)].isdigit()
            and (string[(i + 1)] != '0')
        ) {
            i += 1;
        }
        string = string[(i + 1):];
    }
    return string;
}



with entry {
    print(remove_leading_zeros('hello'));
    print(remove_leading_zeros('Racecar'));
    print(remove_leading_zeros('abcabc'));
}
