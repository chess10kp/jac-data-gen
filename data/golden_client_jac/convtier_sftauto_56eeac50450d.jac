def remove_duplicates(lst: Any) -> object {
    seen = {};
    result = [];
    for item in lst {
        if (item not in seen) {
            seen[item] = True;
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
