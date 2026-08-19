def concatenate_characters(string: Any) -> object {
    if ((len(string) % 2) == 1) {
        middle_index = len(string) // 2;
        return (string[0] + string[-1])
            if (middle_index == 0)
            else (string[0:middle_index] + string[(middle_index + 1):]);
    } else {
        return (string[0] + string[-1]);
    }
}



with entry {
    print(concatenate_characters('hello'));
    print(concatenate_characters('Racecar'));
    print(concatenate_characters('abcabc'));
}
