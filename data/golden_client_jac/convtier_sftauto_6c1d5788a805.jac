def extract_second_to_last_element(lst: Any) -> object {
    length = len(lst);
    if (length >= 2) {
        return lst[-2];
    } else {
        return None;
    }
}



with entry {
    print(extract_second_to_last_element('hello'));
    print(extract_second_to_last_element('Racecar'));
    print(extract_second_to_last_element('abcabc'));
}
