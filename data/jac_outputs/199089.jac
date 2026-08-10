"""Helper for :meth:`analyze`"""
def contains_a_letter(word: Any) -> object {
    for char in word {
        if char.isalpha() {
            return True;
        }
    }
    return False;
}