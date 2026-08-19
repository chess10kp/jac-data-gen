def categorize_strings(string_list: Any) -> object {
    categorized_strings = [];
    for string in string_list {
        if (len(string) < 2) {
            categorized_strings.append((string + " is very short"));
        } elif (len(string) < 5) {
            categorized_strings.append((string + " is short"));
        } elif (len(string) < 9) {
            categorized_strings.append((string + " is medium"));
        } else {
            categorized_strings.append((string + " is long"));
        }
    }
    return categorized_strings;
}



with entry {
    print(categorize_strings('hello'));
    print(categorize_strings('Racecar'));
    print(categorize_strings('abcabc'));
}
