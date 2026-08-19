def swap_case(x: Any) -> object {
    result = '';
    for char in x {
        ascii_value = ord(char);
        if (65 <= ascii_value <= 90) {
            result += chr((ascii_value + 32));
        } elif (97 <= ascii_value <= 122) {
            result += chr((ascii_value - 32));
        } else {
            result += char;
        }
    }
    return result;
}



with entry {
    print(swap_case('hello'));
    print(swap_case('Racecar'));
    print(swap_case('abcabc'));
}
