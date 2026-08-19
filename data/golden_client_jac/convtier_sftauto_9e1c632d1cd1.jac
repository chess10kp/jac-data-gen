def longest_common_prefix(strings: Any) -> object {
    if not strings {
        return "";
    }
    min_length = min(len(string) for string in strings);
    for i in range(min_length) {
        if `any((string[i] != strings[0][i]) for string in strings) {
            return strings[0][:i];
        }
    }
    return strings[0][:min_length];
}



with entry {
    print(longest_common_prefix('hello'));
}
