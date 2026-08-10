"""Use the text in the input string s to create the sentencelength dictionary."""
def makeSentenceLengths(s: str) -> dict[int, int] {
    length = 0;
    lengths = [];
    for word in s.split() {
        length += 1;
        if word[-1] in '?!.' {
            lengths.append(length);
            length = 0;
        }
    }
    sentence_lengths = {};
    for l in lengths {
        if l not in sentence_lengths {
            sentence_lengths[l] = 1;
        } else {
            sentence_lengths[l] += 1;
        }
    }
    return sentence_lengths;
}