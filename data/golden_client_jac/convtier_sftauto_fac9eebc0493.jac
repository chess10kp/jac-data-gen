def remove_duplicates(string: Any) -> object {
    if (len(string) < 2) {
        return string;
    }
    result = [string[0]];
    for i in range(1, len(string)) {
        if (string[i] != string[(i - 1)]) {
            result.append(string[i]);
        }
    }
    return ''.join(result);
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
