def lexicographical_order(arr: Any) -> object {
    unique_strings = `set();
    for string in arr {
        unique_strings.add(string);
    }
    sorted_strings = sorted(unique_strings, reverse=True);
    return sorted_strings;
}



with entry {
    print(lexicographical_order('hello'));
    print(lexicographical_order('Racecar'));
    print(lexicographical_order('abcabc'));
}
