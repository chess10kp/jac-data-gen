def count_distinct_values(arr: Any) -> object {
    distinct_values = [];
    for value in arr {
        if (str(value) not in distinct_values) {
            distinct_values.append(str(value));
        }
    }
    return len(distinct_values);
}



with entry {
    print(count_distinct_values('hello'));
    print(count_distinct_values('Racecar'));
    print(count_distinct_values('abcabc'));
}
