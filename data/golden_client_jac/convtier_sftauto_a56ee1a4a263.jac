def sort_strings(strings: Any) -> object {
    n = len(strings);
    for i in range(n) {
        for j in range(0, (n - i - 1)) {
            if (len(strings[j]) > len(strings[(j + 1)])) {
                (strings[j], strings[(j + 1)]) = (strings[(j + 1)], strings[j]);
            } elif (
                (len(strings[j]) == len(strings[(j + 1)]))
                and (strings[j].lower() > strings[(j + 1)].lower())
            ) {
                (strings[j], strings[(j + 1)]) = (strings[(j + 1)], strings[j]);
            }
        }
    }
    return strings;
}



with entry {
    print(sort_strings([81]));
    print(sort_strings([]));
    print(sort_strings(['a']));
}
