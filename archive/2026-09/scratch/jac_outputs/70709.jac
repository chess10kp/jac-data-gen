"""Manually doing the splits on the spaces."""
def rev_word(s: str) -> str {
    words = [];
    length = len(s);
    spaces = [' '];
    i = 0;
    while i < length {
        if s[i] not in spaces {
            word_start = i;
            while i < length and s[i] not in spaces {
                i += 1;
            }
            words.append(s[word_start:i]);
        }
        i += 1;
    }
    reversed_words = [];
    index_words = len(words) - 1;
    while index_words >= 0 {
        reversed_words.append(words[index_words]);
        index_words -= 1;
    }
    return " ".join(reversed_words);
}