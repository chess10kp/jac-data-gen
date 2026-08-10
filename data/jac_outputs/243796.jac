"""Format author names with abbreviated first names and comma/and separators."""
def authors_to_string(names: list[tuple[str, str, str, str]]) -> str {
    string_authors = '';
    d = ', ';
    for (idx, name) in enumerate(names) {
        (first, von, last, jr) = name;
        if first {
            first = first[0] + '.';
        }
        if idx == len(names) - 2 {
            d = ' and ';
        }
        if idx == len(names) - 1 {
            d = '';
        }
        string_authors += ' '.join([part for part in [first, von, last, jr] if part]) + d;
    }
    return string_authors;
}