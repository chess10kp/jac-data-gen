def longestCommonPrefix(strs: Any) -> object {
    prefix = "";
    if (not strs or (len(min(strs, key=len)) < 3)) {
        return prefix;
    }
    for (i, c) in enumerate(strs[0]) {
        for s in strs[1:] {
            if ((i >= len(s)) or (s[i] != c)) {
                return prefix;
            }
        }
        prefix += c;
    }
    return prefix;
}



with entry {
    print(longestCommonPrefix('hello'));
}
