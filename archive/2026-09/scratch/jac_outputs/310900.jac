"""Returns FIRST_k(word) for terminal-only grammars."""
def first[T](word: T, k: int = 1) -> T {
    return word[:k];
}