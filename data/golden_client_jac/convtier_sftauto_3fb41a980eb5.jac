def get_unique_items(lst: Any) -> object {
    unique_items = [];
    for item in lst {
        if (lst.count(item) == 1) {
            unique_items.append(item);
        }
    }
    return unique_items;
}



with entry {
    print(get_unique_items('hello'));
    print(get_unique_items('Racecar'));
    print(get_unique_items('abcabc'));
}
