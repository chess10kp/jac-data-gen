def duplicate_characters(string: Any) -> object {
    seen = `set();
    output = [];
    for char in string {
        if (char not in seen) {
            output.append(char);
            seen.add(char);
        }
    }
    return ', '.join(output);
}



with entry {
    print(duplicate_characters('hello'));
    print(duplicate_characters('Racecar'));
    print(duplicate_characters('abcabc'));
}
