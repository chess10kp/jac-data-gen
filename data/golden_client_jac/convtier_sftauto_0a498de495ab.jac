def second_biggest(lst: Any) -> object {
    return sorted(lst)[-2];
}



with entry {
    print(second_biggest('hello'));
    print(second_biggest('Racecar'));
    print(second_biggest('abcabc'));
}
