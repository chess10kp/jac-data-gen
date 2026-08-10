"""
    Build SMT formula footer
    """
def footer(id1: str, id2: str | None = None) -> str {
    smt = '(assert {}.allows)\n'.format(id1);
    if id2 {
        smt += '(assert (or {0}.denies {0}.neutral))\n'.format(id2);
    }
    smt += '(check-sat)\n';
    smt += '(get-model)\n';
    return smt;
}