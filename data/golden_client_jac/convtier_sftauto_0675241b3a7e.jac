def count_items(lst: Any) -> object {
    count_dict = {};
    for item in lst {
        if (item in count_dict) {
            count_dict[item] += 1;
        } else {
            count_dict[item] = 1;
        }
    }
    return count_dict;
}



with entry {
    print(count_items('hello'));
    print(count_items('Racecar'));
    print(count_items('abcabc'));
}
