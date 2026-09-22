"""Returns properly formated string for declaring ambiguous constraints,
it takes a list of Rosetta-formated constraints string."""
def AmbiguousCst(cst_lst: list[str]) -> str {
    return 'AmbiguousConstraint\n' + ''.join(cst_lst) + 'END_AMBIGUOUS\n';
}