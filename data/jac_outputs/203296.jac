"""
    True when my_word matches other_word with _ gaps and equal length.
    """
def match_with_gaps(my_word: str, other_word: str) -> bool {
    my_word = my_word.replace('_ ', '_');
    other_word_letters: list[str] = [];
    non_other_word_letters: list[str] = [];
    if len(my_word) != len(other_word) {
        return False;
    }
    for (index, letter) in enumerate(my_word) {
        other_letter = other_word[index];
        if letter == '_' {
            non_other_word_letters.append(other_letter);
            if other_letter in other_word_letters {
                return False;
            }
        } else {
            other_word_letters.append(other_letter);
            if letter != other_letter or letter in non_other_word_letters {
                return False;
            }
        }
    }
    return True;
}