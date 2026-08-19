def get_unique_alphabets(input_string: Any) -> object {
    unique_alphabets = [];
    lower_string = input_string.lower();
    for char in lower_string {
        if (char.isalpha() and (char not in unique_alphabets)) {
            unique_alphabets.append(char);
        }
    }
    sorted_unique_alphabets = sorted(unique_alphabets);
    return sorted_unique_alphabets;
}



with entry {
    print(get_unique_alphabets('hello'));
    print(get_unique_alphabets('Racecar'));
    print(get_unique_alphabets('abcabc'));
}
