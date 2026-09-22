"""
Return all the `n`-grams in the list `words`.  The n-grams are
returned as a list of tuples, each tuple containing an n-gram, as
per the description in `candidate_answers`.
"""
def ngrams(words: list[str], n: int = 1) -> list[tuple[str, ...]] {
    [tuple(words[j:(j + n)]) for j in range(len(words) - n + 1)]
}