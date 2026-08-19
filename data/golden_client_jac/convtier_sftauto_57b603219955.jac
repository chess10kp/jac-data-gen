def remove_duplicates(array: Any) -> object {
    output = [];
    seen = `set();
    for element in array {
        if (element not in seen) {
            seen.add(element);
            output.append(element);
        }
    }
    output.sort();
    return output;
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
