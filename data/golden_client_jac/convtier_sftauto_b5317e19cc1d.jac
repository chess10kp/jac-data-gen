def remove_duplicates(arr: Any) -> object {
    unique_elements = `set();
    result = [];
    for element in arr {
        if (element not in unique_elements) {
            unique_elements.add(element);
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
