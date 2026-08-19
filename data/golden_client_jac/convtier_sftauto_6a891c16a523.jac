def remove_duplicates(strings: Any) -> object {
    seen = `set();
    non_duplicates = [];
    for string in strings {
        string = string.strip();
        if (string.lower() not in seen) {
            seen.add(string.lower());
            non_duplicates.append(string);
        }
    }
    return non_duplicates;
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
