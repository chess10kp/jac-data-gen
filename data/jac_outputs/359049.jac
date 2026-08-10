"""Split a word separated by a | symbol, or duplicate it when no pipe is present."""
def split_word_at_pipe(word: str) -> list[str] {
    if '|' in word {
        return word.split('|');
    }
    return [word, word];
}