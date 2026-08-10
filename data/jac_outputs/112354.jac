"""
    Print the contents of a dictionary
    """
def show_dictionary(name: str, d: dict[str, object | None]) -> str {
    text = [("[%s]" % name)];
    for key in d {
        text.append("\t%s = %s" % (key, d[key] if d[key] is not None else '<Not set>'));
    }
    return '\n'.join(text);
}