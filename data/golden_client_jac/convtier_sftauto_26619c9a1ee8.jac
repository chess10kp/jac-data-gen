def count_elements(lst: Any) -> object {
    count = 0;
    for element in lst {
        count += 1;
    }
    return count;
}



with entry {
    print(count_elements('hello'));
    print(count_elements('Racecar'));
    print(count_elements('abcabc'));
}
