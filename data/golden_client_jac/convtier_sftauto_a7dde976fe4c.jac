def is_pangram_with_counts(string: Any) -> object {
    counts = [0] * 26;
    string = string.lower();
    for char in string {
        if ('a' <= char <= 'z') {
            counts[(ord(char) - ord('a'))] += 1;
        }
    }
    return all(counts);
}



with entry {
    print(is_pangram_with_counts('hello'));
}
