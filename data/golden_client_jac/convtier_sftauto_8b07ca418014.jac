def longest_uppercase_run(string: Any) -> object {
    max_run = 0;
    current_run = 0;
    for i in range(len(string)) {
        if string[i].isupper() {
            current_run += 1;
            max_run = max(max_run, current_run);
        } else {
            current_run = 0;
        }
    }
    return max_run;
}



with entry {
    print(longest_uppercase_run('hello'));
    print(longest_uppercase_run('Racecar'));
}
