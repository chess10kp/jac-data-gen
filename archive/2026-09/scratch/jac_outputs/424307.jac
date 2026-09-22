"""Cull candidates that do not start with ``text``.

Returned candidates also have a space appended.
"""
def cull_candidates(candidates: list[str], text: str, sep: str = ' ') -> list[str] {
    return [
        c.rstrip(sep) + sep
        for c in candidates
        if c and c.startswith(text)
    ];
}