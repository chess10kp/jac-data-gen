def remove_consecutive_reverse(s: Any) -> object {
    if (len(s) <= 1) {
        return s;
    }
    if (s[0] == s[1]) {
        return remove_consecutive_reverse(s[1:]);
    }
    return (remove_consecutive_reverse(s[1:]) + s[0]);
}



with entry {
    print(remove_consecutive_reverse([81]));
    print(remove_consecutive_reverse([]));
    print(remove_consecutive_reverse(['a']));
}
