def count_unique_digits(num: Any) -> object {
    digits = `set();
    num = str(num);
    for digit in num {
        if (digit != '-') {
            digits.add(digit);
        }
    }
    return len(digits);
}



with entry {
    print(count_unique_digits('hello'));
    print(count_unique_digits('Racecar'));
    print(count_unique_digits('abcabc'));
}
