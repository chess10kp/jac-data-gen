def concatenate_first_and_last(string: Any) -> object {
    length = len(string);
    if ((length % 2) == 1) {
        middle_index = length // 2;
        return (string[0] + string[(middle_index + 1):] + string[-1]);
    } else {
        return (string[0] + string[1:] + string[-1]);
    }
}



with entry {
    print(concatenate_first_and_last('hello'));
    print(concatenate_first_and_last('Racecar'));
    print(concatenate_first_and_last('abcabc'));
}
