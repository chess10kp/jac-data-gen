"""Determine if new_group should be added to pipetting operation."""
def det_new_group(i: int, base: int = 0) -> bool {
    assert isinstance(i, int), "Needs an integer.";
    assert isinstance(base, int), "Base has to be an integer";
    return i == base;
}