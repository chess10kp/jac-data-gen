"""Evaluate word's score. If the word contains letters outside provided scope,
the output will be \infty.
"""
def calc_word_score(word: str, letters_count: dict[str, int], letters_score: dict[str, int]) -> int {
    output = 0;
    letters_remaining = dict(letters_count);
    for w in word {
        if w not in letters_count {
            return 0;
        }
        if letters_remaining[w] == 0 {
            return 0;
        }
        output += letters_score[w];
        letters_remaining[w] -= 1;
    }
    return output;
}