def total_characters(strings: Any) -> object {
    count = 0;
    for string in strings {
        for char in string {
            if (unicodedata.category(char)[0] not in ('C', 'Z', 'N')) {
                count += 1;
            }
        }
    }
    return count;
}



with entry {
    print(total_characters([]));
}
