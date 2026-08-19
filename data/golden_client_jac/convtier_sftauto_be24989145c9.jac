def find_maximum(lst: Any) -> object {
    if (len(lst) == 0) {
        return None;
    }
    max_num = lst[0];
    for num in lst[1:] {
        if (num > max_num) {
            max_num = num;
        }
    }
    return max_num;
}



with entry {
    print(find_maximum('hello'));
    print(find_maximum('Racecar'));
    print(find_maximum('abcabc'));
}
