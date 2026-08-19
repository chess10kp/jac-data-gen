def count_unique_three_letter_words(string: Any) -> object {
    count = 0;
    seen = [False] * (26 * 26 * 26);
    for i in range((len(string) - 2)) {
        index = (
            ((ord(string[i]) - ord('a')) * 26 * 26) + (
                (ord(string[(i + 1)]) - ord('a')) * 26
            ) + (ord(string[(i + 2)]) - ord('a'))
        );
        if not seen[index] {
            count += 1;
            seen[index] = True;
        }
    }
    return count;
}



with entry {
    print(count_unique_three_letter_words('hello'));
    print(count_unique_three_letter_words('Racecar'));
    print(count_unique_three_letter_words([]));
}
