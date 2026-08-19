def removeDuplicates(s: Any) -> object {
    result = '';
    encountered = 0;
    for char in s {
        ascii_value = ord(char);
        if not (encountered & (1 << ascii_value)) {
            result += char;
            encountered |= 1 << ascii_value;
        }
    }
    return result;
}



with entry {
    print(removeDuplicates('hello'));
    print(removeDuplicates('Racecar'));
    print(removeDuplicates('abcabc'));
}
