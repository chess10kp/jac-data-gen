def get_next_element(lst: Any) -> object {
    if (len(lst) <= 1) {
        return None;
    }
    return lst[1];
}



with entry {
    print(get_next_element('hello'));
    print(get_next_element('Racecar'));
    print(get_next_element('abcabc'));
}
