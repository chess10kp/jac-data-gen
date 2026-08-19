def remove_duplicates(lst: Any) -> object {
    result = [];
    for i in range(len(lst)) {
        if ((i < (len(lst) - 1)) and (lst[i] == lst[(i + 1)])) {
            continue;
        }
        result.append(lst[i]);
    }
    return result;
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
