def reverse_string(s: Any) -> object {
    if (len(s) <= 1) {
        return s;
    } else {
        mid = len(s) // 2;
        left_half = reverse_string(s[:mid]);
        right_half = reverse_string(s[mid:]);
        return (right_half + left_half);
    }
}



with entry {
    print(reverse_string([]));
}
