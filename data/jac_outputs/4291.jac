"""Use the sphinx naming style for anchors of headings."""
def to_nbsphinx(s: str) -> str {
    s = s.replace(" ", "-").lower();
    return "".join(filter(lambda (c: str) { c not in "()" }, s));
}