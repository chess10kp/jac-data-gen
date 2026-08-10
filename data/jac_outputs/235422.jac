"""Return the Levenshtein edit distance between two strings *a* and *b*."""
def levenshtein_distance(a: Any, b: Any) -> object {
    if (a == b) {
        return 0;
    }
    if (len(a) < len(b)) {
        (a, b) = (b, a);
    }
    if not a {
        return len(b);
    }
    previous_row = range((len(b) + 1));
    for (i, column1) in enumerate(a) {
        current_row = [(i + 1)];
        for (j, column2) in enumerate(b) {
            insertions = previous_row[(j + 1)] + 1;
            deletions = current_row[j] + 1;
            substitutions = previous_row[j] + (column1 != column2);
            current_row.append(min(insertions, deletions, substitutions));
        }
        previous_row = current_row;
    }
    return previous_row[-1];
}