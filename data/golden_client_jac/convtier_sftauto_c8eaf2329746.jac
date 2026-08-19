def reverse_string(string: Any) -> object {
    length = len(string);
    start = 0;
    end = length - 1;
    while (start < end) {
        string = swap_characters(string, start, end);
        start += 1;
        end -= 1;
    }
    return string;
}



with entry {
    print(reverse_string([81]));
    print(reverse_string([]));
    print(reverse_string(['a']));
}
