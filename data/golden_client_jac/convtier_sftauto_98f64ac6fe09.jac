def count_distinct_states(matrix: Any) -> object {
    count = 0;
    states = `set();
    for row in matrix {
        for col in row {
            state = ''.join(col);
            if (state not in states) {
                count += 1;
            }
            states.add(state);
        }
    }
    return count;
}



with entry {
    print(count_distinct_states('hello'));
    print(count_distinct_states('Racecar'));
    print(count_distinct_states('abcabc'));
}
