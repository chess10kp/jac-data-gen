def reverse_string(s: str) -> str {
    if (len(s) <= 1) {
        return s;
    } else {
        return (reverse_string(s[1:]) + s[0]);
    }
}



with entry {
    print(reverse_string([81]));
    print(reverse_string([]));
    print(reverse_string(['a']));
}
