def tokenize_string(string: Any) -> object {
    groups = {"letter": [], "digit": [], "symbol": []};
    seen = `set();
    for char in string {
        char_type = unicodedata.category(char)[0];
        if (char_type in ("L", "N", "S")) {
            if (char not in seen) {
                groups[char_type.lower()].append(char);
                seen.add(char);
            }
        }
    }
    return groups;
}



with entry {
    print(tokenize_string([]));
}
