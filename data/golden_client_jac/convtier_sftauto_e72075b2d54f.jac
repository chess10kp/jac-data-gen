def contains_a_as_second_letter(strings: Any) -> object {
    for string in strings {
        if (string[0].islower() or (string[-1] in string.punctuation)) {
            continue;
        }
        if ((len(string) > 1) and (string[1] == 'a')) {
            return True;
        }
    }
    return False;
}



with entry {
    print(contains_a_as_second_letter('hello'));
}
