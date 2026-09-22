"""Convert a string to title case."""
def title_case(sentence: object) -> str {
    if not isinstance(sentence, str) {
        raise TypeError(('Invalid input %s - Input must be type string' % sentence));
    }
    if not sentence {
        raise ValueError('Cannot apply title function to empty string.');
    }
    ret = '';
    for (i, ch) in enumerate(sentence) {
        if i == 0 or sentence[i - 1] == ' ' {
            ret += ch.upper();
        } else {
            ret += ch.lower();
        }
    }
    return ret;
}