"""
    Given a set of reference values and a set of test values, return
    the fraction of test values that appear in the reference set.
    If test is empty, then return None.
    """
def term_precision(reference: set[object], `test: set[object]) -> float | None {
    if not hasattr(reference, 'intersection') or not hasattr(`test, 'intersection') {
        raise TypeError('reference and test should be sets');
    }
    if len(`test) == 0 {
        return None;
    }
    return round(len(reference.intersection(`test)) / len(`test), 3);
}