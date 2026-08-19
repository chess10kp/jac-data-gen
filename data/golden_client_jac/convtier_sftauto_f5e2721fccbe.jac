def find_duplicates(arr: Any) -> object {
    seen = `set();
    duplicates = [];
    for num in arr {
        if ((num in seen) and (num not in duplicates)) {
            duplicates.append(num);
        }
        seen.add(num);
    }
    duplicates.sort();
    return duplicates;
}



with entry {
    print(find_duplicates('hello'));
    print(find_duplicates('Racecar'));
    print(find_duplicates('abcabc'));
}
