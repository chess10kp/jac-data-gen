def remove_duplicates(objects: Any) -> object {
    seen = `set();
    result = [];
    for `obj in objects {
        if (`obj not in seen) {
            seen.add(`obj);
            result.append(`obj);
        }
    }
    return result;
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
