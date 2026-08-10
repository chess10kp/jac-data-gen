"""Determine if the index is at 'aB', which is the start of a camel token.
For example, with 'workAt', this function detects 'kA'."""
def _is_camel_case_ab(s: str, index: int) -> bool {
    return index >= 1 and s[index - 1].islower() and s[index].isupper();
}