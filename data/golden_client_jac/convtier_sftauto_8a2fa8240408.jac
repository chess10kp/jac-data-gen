def remove_duplicates(arr: Any) -> object {
    seen = `set();
    result = [];
    for num in arr {
        if (num not in seen) {
            result.append(num);
            seen.add(num);
        }
    }
    return result;
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
