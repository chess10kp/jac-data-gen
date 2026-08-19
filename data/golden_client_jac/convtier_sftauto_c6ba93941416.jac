def count_unique_three_letter_words(s: Any) -> object {
    count = 0;
    visited = [False] * (26 * 26 * 26);
    for i in range((len(s) - 2)) {
        word = s[i:(i + 3)];
        index = (
            ((ord(word[0]) - ord('a')) * 26 * 26) + ((ord(word[1]) - ord('a')) * 26) + (
                ord(word[2]) - ord('a')
            )
        );
        if not visited[index] {
            count += 1;
            visited[index] = True;
        }
    }
    return count;
}



with entry {
    print(count_unique_three_letter_words('hello'));
    print(count_unique_three_letter_words('Racecar'));
    print(count_unique_three_letter_words([2, 9]));
}
