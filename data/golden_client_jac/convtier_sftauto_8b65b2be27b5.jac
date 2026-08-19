def remove_duplicates(lst: Any) -> object {
    unique_list = [];
    seen = `set();
    for element in lst {
        if (element not in seen) {
            unique_list.append(element);
            seen.add(element);
        }
    }
    return unique_list;
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
