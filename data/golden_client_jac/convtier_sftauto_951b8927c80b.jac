def count_distinct_states(matrix: Any) -> object {
    count = 0;
    states = `set();
    for row in matrix {
        for col in row {
            if (col not in states) {
                count += 1;
            }
            states.add(col);
        }
    }
    return count;
}



with entry {
    print(count_distinct_states('hello'));
    print(count_distinct_states('Racecar'));
    print(count_distinct_states('abcabc'));
}
