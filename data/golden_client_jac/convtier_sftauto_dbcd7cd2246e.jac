def remove_empty_strings(lst: Any) -> object {
    result = [];
    for string in lst {
        if string {
            result.append(string);
        }
    }
    return result;
}



with entry {
    print(remove_empty_strings('hello'));
    print(remove_empty_strings('Racecar'));
    print(remove_empty_strings('abcabc'));
}
