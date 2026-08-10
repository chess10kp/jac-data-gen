"""Return a copy of the passed string, each line indented by
    1 tab. The first line is not indented. If you want to
    change the number of tabs or indent the first line too
    you can pass additional parameters to the filter:

    .. sourcecode:: jinja

        {{ mytext|indent(2, true, 'x') }}
            indent by two 'x' and indent the first line too.
    """
def smartindent(
    s: str, width: int = 1, indentfirst: bool = False, indentchar: str = '\t'
) -> str {
    indention = indentchar * width;
    rv = ('\n' + indention).join(s.splitlines());
    if indentfirst {
        rv = indention + rv;
    }
    return rv;
}