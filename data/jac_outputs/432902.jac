"""Return whether words in list are sorted alphabetically."""
def words_are_alphabetic(word_list: list[str], debug: bool) -> bool {
    return sorted(word_list) == word_list;
}