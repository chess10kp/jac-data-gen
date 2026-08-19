def count_occurrences(string: Any) -> object {
    count = 0;
    for char in string {
        if ((char.lower() == 'a') or (char.lower() == 'á')) {
            count += 1;
        }
    }
    return count;
}



with entry {
    print(count_occurrences('hello'));
    print(count_occurrences('Racecar'));
    print(count_occurrences(['a']));
}
