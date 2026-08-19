def string_to_sorted_list(s: Any) -> object {
    char_list = `list(s);
    char_list.sort(reverse=True);
    sorted_list = [str(char) for char in char_list];
    return sorted_list;
}



with entry {
    print(string_to_sorted_list('hello'));
    print(string_to_sorted_list('Racecar'));
    print(string_to_sorted_list('abcabc'));
}
