def longest_common_prefix(strs: Any) -> object {
    if not strs {
        return "";
    }
    prefix = "";
    for i in range(len(strs[0])) {
        for string in strs[1:] {
            if ((i >= len(string)) or (string[i] != strs[0][i])) {
                return prefix;
            }
        }
        prefix += strs[0][i];
    }
    return prefix;
}



with entry {
    print(longest_common_prefix('hello'));
    print(longest_common_prefix(['a', 'a']));
}
