def reverse_string(s: Any) -> object {
    if (len(s) == 0) {
        return s;
    } else {
        return (reverse_string(s[1:]) + s[0]);
    }
}



with entry {
    print(reverse_string([]));
}
