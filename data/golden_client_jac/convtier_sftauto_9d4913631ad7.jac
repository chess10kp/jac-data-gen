def remove_duplicates(arr: List[int]) -> List[int] {
    seen = `set();
    result = [];
    for num in arr {
        if (num not in seen) {
            seen.add(num);
            result.append(num);
        }
    }
    result.sort();
    return result;
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
