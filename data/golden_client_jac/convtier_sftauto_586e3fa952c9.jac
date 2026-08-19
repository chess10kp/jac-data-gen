def string_indices(lst: Any) -> object {
    indices_dict = {};
    for (i, string) in enumerate(lst) {
        if (string not in indices_dict) {
            indices_dict[string] = [i];
        } else {
            indices_dict[string].append(i);
        }
    }
    return indices_dict;
}



with entry {
    print(string_indices('hello'));
    print(string_indices('Racecar'));
    print(string_indices('abcabc'));
}
