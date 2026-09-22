"""Convert a sequence of constraint tuples as used in PackageMetadata to a
list of pretty constraint strings."""
def constraints_to_pretty_strings(
    constraint_tuples: tuple[tuple[str, tuple[tuple[str, ...], ...]], ...]
) -> list[str] {
    return [
        "{} {}".format(dist, constraint_string).strip()
        for (dist, disjunction) in constraint_tuples for conjunction in disjunction
        for constraint_string in conjunction
    ];
}