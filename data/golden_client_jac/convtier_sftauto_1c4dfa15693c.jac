def match_strings(patterns: Any) -> object {
    result = [];
    for (string, pattern) in patterns {
        if re.search(pattern, string) {
            result.append(True);
        } else {
            result.append(False);
        }
    }
    return result;
}



with entry {
    print(match_strings([]));
}
