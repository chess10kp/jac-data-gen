"""innerstring_rules: declaration separated from impl; token bound via an `any` glob."""

import from pygments.token { String }

# Untyped Pygments token bound through an `any` glob so String.Interpol / String.Single
# attribute access passes the type checker.
glob Tok: any = String;

"""Old-style and new-style string-interpolation rules for a plain string body."""
def innerstring_rules(ttype: any) -> list;

impl innerstring_rules {
    return [
            # the old style '%s' % (...) string formatting (still valid in Py3)
            (
                r"%(\(\w+\))?[-#0 +]*([0-9]+|[*])?(\.([0-9]+|[*]))?" +
                "[hlL]?[E-GXc-giorsaux%]",
                Tok.Interpol,
            ),
            # the new style '{}'.format(...) string formatting
            (
                r"\{" +
                r"((\w+)((\.\w+)|(\[[^\]]+\]))*)?" +  # field name
                r"(\![sra])?" +  # conversion
                r"(\:(.?[<>=\^])?[-+ ]?#?0?(\d+)?,?(\.\d+)?[E-GXb-gnosx%]?)?" +
                r"\}",
                Tok.Interpol,
            ),
            # backslashes, quotes and formatting signs must be parsed one at a time
            (r'[^\\\'"%{\n]+', ttype),
            (r'[\'"\\]', ttype),
            # unhandled string formatting sign
            (r"%|(\{{1,2})", ttype),
        ];
}

with entry {
    rules = innerstring_rules(Tok.Single);
    print(len(rules));
    for r in rules {
        print(r[0]);
    }
}
