"""Count the number of `(` and `)` in the given string."""
def _count_parenthesis(value: str) -> int {
    return sum(i for (i, c) in enumerate(value) if c in ('(', ')'));
}