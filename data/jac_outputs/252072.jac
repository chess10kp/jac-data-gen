"""Statistic function. Returs the count of the atuomaton transtions.
    The calculation is done only from the a given transition dictionary.
    The forward and backward transtion dictionary might coresponded, for
    better results.
    """
def transitionsCount(trans: dict[str, dict[str, list]]) -> int {
    count = 0;
    for from_state in trans {
        for letter in trans[from_state] {
            count += len(trans[from_state][letter]);
        }
    }
    return count;
}