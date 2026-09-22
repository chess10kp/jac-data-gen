"""str: Convert the given function arguments into an UltiSnips-style snippet."""
def get_argument_tabstops(arguments: list[str]) -> list[str] {
    offset = 1;
    return [
        '${{{tabstop}:{name}}}'.format(tabstop=(index + offset), name=name)
        for (index, name) in enumerate(arguments)
    ];
}