def list_to_string(lst: Any) -> object {
    return ', '.join(str(num) for num in lst);
}



with entry {
    print(list_to_string('hello'));
    print(list_to_string('Racecar'));
    print(list_to_string('abcabc'));
}
