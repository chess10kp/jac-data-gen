def find_max_value(lst: Any) -> object {
    if not lst {
        return None;
    }
    max_value = lst[0];
    for num in lst {
        if (num > max_value) {
            max_value = num;
        }
    }
    return max_value;
}



with entry {
    print(find_max_value('hello'));
    print(find_max_value('Racecar'));
    print(find_max_value('abcabc'));
}
