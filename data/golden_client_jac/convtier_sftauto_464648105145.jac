def reverse_and_remove_duplicates(string: Any) -> object {
    reversed_string = "";
    for char in string {
        if (char not in reversed_string) {
            reversed_string += char;
        }
    }
    return reversed_string[::-1];
}



with entry {
    print(reverse_and_remove_duplicates('hello'));
    print(reverse_and_remove_duplicates('Racecar'));
    print(reverse_and_remove_duplicates('abcabc'));
}
