def swap_case(string: Any) -> object {
    swapped_string = "";
    for char in string {
        if char.islower() {
            swapped_string += char.upper();
        } elif char.isupper() {
            swapped_string += char.lower();
        } else {
            swapped_string += char;
        }
    }
    return swapped_string;
}



with entry {
    print(swap_case('hello'));
    print(swap_case('Racecar'));
    print(swap_case('abcabc'));
}
