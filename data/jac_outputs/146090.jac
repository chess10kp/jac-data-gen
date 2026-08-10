"""Slice string s at integer inds in vec."""
def _sliceString(s: str, vec: list[int]) -> str {
    ''.join([s[i] for i in vec])
}