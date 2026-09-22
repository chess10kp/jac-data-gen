"""
Parse a list of strings and return the "best" element based on criteria.

criteria is '>'-separated substrings sought in descending order.
'+' is a logical 'and', '=' substitutes: A=B returns B if A is found.
"""
def find_best(strings: list[str], criteria: str) -> str {
    (criterion, _, further_criteria) = criteria.partition('>');
    wanted = criterion.partition('=')[0].split('+');
    if all(w in strings or w == '' for w in wanted) {
        return criterion.rpartition('=')[2];
    }
    return find_best(strings, further_criteria);
}