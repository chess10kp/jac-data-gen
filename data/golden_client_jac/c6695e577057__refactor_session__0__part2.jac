"""fstring_rules: declaration separated from impl; token bound via an `any` glob."""

import from pygments.token { String }

# Pygments' token objects are untyped to the checker; bind through an `any`
# glob so attribute access (String.Interpol, String.Double) type-checks.
glob Tok: any = String;

"""Interpolation rules for an f-string body (a `{` opens a nested expr state)."""
def fstring_rules(ttype: any) -> list;

impl fstring_rules {
    return [
            # Assuming that a '}' is the closing brace after format specifier.
            (r"\}", Tok.Interpol),
            (r"\{", Tok.Interpol, "expr-inside-fstring"),
            # backslashes, quotes and formatting signs must be parsed one at a time
            (r'[^\\\'"{}\n]+', ttype),
            (r'[\'"\\]', ttype),
        ];
}

with entry {
    rules = fstring_rules(Tok.Double);
    print(len(rules));
    for r in rules {
        print(r[0]);
    }
}
