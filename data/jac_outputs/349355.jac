"""
    Finds indices of character `ch` in string `s`
    """
def _find(s: str, ch: str) -> list[int] {
    [
        i
        for (i, ltr) in enumerate(s)
        if ltr == ch
    ]
}