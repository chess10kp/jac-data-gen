"""Check if str_1 and str_2 are permutations of each other."""
def is_permutation_nocounter(str_1: str, str_2: str) -> bool {
    if not isinstance(str_1, str) or not isinstance(str_2, str) {
        raise TypeError;
    }
    if len(str_1) != len(str_2) {
        return False;
    }
    str_1_char_freq = {char: str_1.count(char) for char in set(str_1)};
    str_2_char_freq = {char: str_2.count(char) for char in set(str_2)};
    str_1_char_freq == str_2_char_freq
}