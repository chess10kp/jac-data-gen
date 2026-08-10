"""Return word list with punctuation and numbers filtered out."""
def punct(w_list: list[str]) -> list[str] {
    [word for word in w_list if word.isalpha()]
}