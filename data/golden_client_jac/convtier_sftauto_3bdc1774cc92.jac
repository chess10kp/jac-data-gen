def remove_duplicates(lst: Any) -> object {
    return [
        x
        for (i, x) in enumerate(lst)
        if (x not in lst[:i])
    ];
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
