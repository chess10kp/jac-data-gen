def swap_case(string: Any) -> object {
    result = '';
    for char in string {
        if char.islower() {
            result += char.upper();
        } elif char.isupper() {
            result += char.lower();
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
