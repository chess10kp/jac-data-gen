"""Given a list of literals and encoding information, returns a list of
lines that implement the 'exactly one' constraint on the list of literals
(that can then be inserted into a CNF file)."""
def exactly_one_constraint(literals: list[str], encoding: str) -> list[str] {
    return ['{} 0'.format(' '.join(literals))] + [
        '-{} -{} 0'.format(literals[i], literals[j])
        for i in range(len(literals))
        for j in range(i + 1, len(literals))
    ];
}