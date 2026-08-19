def unique_substrings(s: Any) -> object {
    def helper(s: Any, index: Any, result: Any) -> object {
        if (index >= len(s)) {
            return result;
        }
        for i in range((index + 1), (len(s) + 1)) {
            substring = s[index:i];
            if ((len(substring) > 1) and (substring not in result)) {
                result.append(substring);
            }
        }
        return helper(s, (index + 1), result);
    }
    return sorted(helper(s, 0, []), key=len);
}



with entry {
    print(unique_substrings('hello'));
    print(unique_substrings('Racecar'));
    print(unique_substrings('abcabc'));
}
