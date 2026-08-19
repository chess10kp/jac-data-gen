def create_array(string: Any) -> object {
    return [char for char in string];
}



with entry {
    print(create_array('hello'));
    print(create_array('Racecar'));
    print(create_array('abcabc'));
}
