def count_distinct_characters(string: Any) -> object {
    distinct_characters = `set(string);
    return len(distinct_characters);
}



with entry {
    print(count_distinct_characters('hello'));
    print(count_distinct_characters('Racecar'));
    print(count_distinct_characters('abcabc'));
}
