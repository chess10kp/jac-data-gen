def find_first_repeating(arr: Any) -> object {
    seen = `set();
    for num in arr {
        if (num in seen) {
            return num;
        }
        seen.add(num);
    }
    return -1;
}



with entry {
    print(find_first_repeating('hello'));
    print(find_first_repeating('Racecar'));
    print(find_first_repeating('abcabc'));
}
