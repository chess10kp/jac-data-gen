def remove_duplicates(array: Any) -> object {
    seen = `set();
    result = [];
    for element in array {
        if (element not in seen) {
            seen.add(element);
            result.append(element);
        }
    }
    return result;
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
