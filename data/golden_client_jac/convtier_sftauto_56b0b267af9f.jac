def remove_and_sort(string: Any) -> object {
    new_string = "";
    for char in string {
        if char.isalpha() {
            new_string += char;
        }
    }
    sorted_string = sorted(new_string, reverse=True);
    return "".join(sorted_string);
}



with entry {
    print(remove_and_sort('hello'));
    print(remove_and_sort('Racecar'));
    print(remove_and_sort('abcabc'));
}
