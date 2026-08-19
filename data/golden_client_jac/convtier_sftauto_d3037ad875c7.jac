def generate_next_line(parent_line: Any) -> object {
    next_line = [1];
    for i in range((len(parent_line) - 1)) {
        next_line.append((parent_line[i] + parent_line[(i + 1)]));
    }
    next_line.append(1);
    return next_line;
}



with entry {
    print(generate_next_line('hello'));
    print(generate_next_line('Racecar'));
    print(generate_next_line('abcabc'));
}
