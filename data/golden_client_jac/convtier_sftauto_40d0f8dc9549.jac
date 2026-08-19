def reverse_and_remove_duplicates(string: Any) -> object {
    reversed_string = string[::-1];
    unique_string = "";
    for char in reversed_string {
        if (char not in unique_string) {
            unique_string += char;
        }
    }
    return unique_string;
}



with entry {
    print(reverse_and_remove_duplicates('hello'));
    print(reverse_and_remove_duplicates('Racecar'));
    print(reverse_and_remove_duplicates('abcabc'));
}
