def remove_duplicates(lst: Any) -> object {
    seen = `set();
    result = [];
    for item in lst {
        if isinstance(item, (`list, `set)) {
            item = remove_duplicates(item);
        } elif isinstance(item, `dict) {
            item = remove_duplicates(`list(item.items()));
        }
        if (item not in seen) {
            seen.add(item);
            result.append(item);
        }
    }
    return result;
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
