def find_unique_substrings(string: str) -> List[str] {
    substrings = [];
    for i in range(len(string)) {
        for j in range((i + 1), (len(string) + 1)) {
            substring = string[i:j];
            if not `any((substring in s) for s in substrings) {
                substrings.append(substring);
            }
        }
    }
    return substrings;
}



with entry {
    print(find_unique_substrings('hello'));
    print(find_unique_substrings('Racecar'));
    print(find_unique_substrings('abcabc'));
}
