"""
Adds word boundary characters to the start and end of an
expression to require that the match occur as a whole word,
but do so respecting the fact that strings starting or ending
with non-word characters will change word boundaries.
"""
def _re_word_boundary(r: str) -> str {
    return r"(^|\W)%s(\W|$)" % (r,);
}