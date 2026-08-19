def generate_subsets(string: Any) -> object {
    subsets = `set();
    n = len(string);
    for i in range(n) {
        for j in range((i + 1), (n + 1)) {
            subset = string[i:j];
            if (len(`set(subset)) == len(subset)) {
                subsets.add(subset);
            }
        }
    }
    sorted_subsets = sorted(subsets);
    return sorted_subsets[::-1];
}



with entry {
    print(generate_subsets('hello'));
    print(generate_subsets('Racecar'));
    print(generate_subsets('abcabc'));
}
