def get_unique_combinations(string: Any) -> object {
    unique_combinations = [];
    length = len(string);
    for i in range(length) {
        unique_combinations.append(string[i]);
        for j in range((i + 1), length) {
            substring = string[i:(j + 1)];
            if (len(`set(substring)) == len(substring)) {
                unique_combinations.append(substring);
            }
        }
    }
    return unique_combinations;
}



with entry {
    print(get_unique_combinations('hello'));
    print(get_unique_combinations('Racecar'));
    print(get_unique_combinations('abcabc'));
}
