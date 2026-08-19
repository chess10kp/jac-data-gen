def find_max(lst: Any) -> object {
    if not lst {
        return None;
    }
    max_val = lst[0];
    for num in lst {
        if (num > max_val) {
            max_val = num;
        }
    }
    return max_val;
}



with entry {
    print(find_max('hello'));
    print(find_max('Racecar'));
    print(find_max('abcabc'));
}
