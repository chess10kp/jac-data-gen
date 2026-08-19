def remove_duplicates(arr: Any) -> object {
    if (len(arr) < 2) {
        return arr;
    }
    seen = {};
    result = [];
    for num in arr {
        if (num not in seen) {
            seen[num] = True;
            result.append(num);
        }
    }
    return result;
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
