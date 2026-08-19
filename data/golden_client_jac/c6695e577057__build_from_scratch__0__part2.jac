import from pygments.token { String }

"""Interpolation rules for an f-string body (a `{` opens a nested expr state)."""
def fstring_rules(ttype: any) -> list {
    return [
            # Assuming that a '}' is the closing brace after format specifier.
            # Sadly, this means that we won't detect syntax error. But it's
            # more important to parse correct syntax correctly, than to
            # highlight invalid syntax.
            (r"\}", String.Interpol),
            (r"\{", String.Interpol, "expr-inside-fstring"),
            # backslashes, quotes and formatting signs must be parsed one at a time
            (r'[^\\\'"{}\n]+', ttype),
            (r'[\'"\\]', ttype),
            # newlines are an error (use "nl" state)
        ];
}

with entry {
    rules = fstring_rules(String.Double);
    print(len(rules));
    for r in rules {
        print(r[0]);
    }
}
