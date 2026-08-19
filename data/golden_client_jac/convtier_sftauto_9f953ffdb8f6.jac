def compact_list(my_list: Any) -> object {
    result = [];
    prev = None;
    for (i, num) in enumerate(my_list) {
        if (((i % 2) == 0) and (num != prev)) {
            result.append(num);
        }
        prev = num;
    }
    return result;
}



with entry {
    print(compact_list('hello'));
    print(compact_list('Racecar'));
    print(compact_list('abcabc'));
}
