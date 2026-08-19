"""RL driver (pure-lib): source_lexer.innerstring_rules (build plain-string highlight rules).

Origin: this_is_jac/source_lexer.jac (the innerstring_rules logic, isolated from the
Pygments RegexLexer/token-table machinery). Deterministic: the body returns a fixed list
of regex-string + token-type rule tuples built from constant raw-string fragments, so the
projection (rule count + each regex pattern) is identical every run. The marked body is the
unit the policy must regenerate; the with entry block exercises it on a fixed token type and
prints a deterministic projection.
"""

import from pygments.token { String }

"""Old-style and new-style string-interpolation rules for a plain string body."""
def innerstring_rules(ttype: any) -> list {
    return [
            # the old style '%s' % (...) string formatting (still valid in Py3)
            (
                r"%(\(\w+\))?[-#0 +]*([0-9]+|[*])?(\.([0-9]+|[*]))?" +
                "[hlL]?[E-GXc-giorsaux%]",
                String.Interpol,
            ),
            # the new style '{}'.format(...) string formatting
            (
                r"\{" +
                r"((\w+)((\.\w+)|(\[[^\]]+\]))*)?" +  # field name
                r"(\![sra])?" +  # conversion
                r"(\:(.?[<>=\^])?[-+ ]?#?0?(\d+)?,?(\.\d+)?[E-GXb-gnosx%]?)?" +
                r"\}",
                String.Interpol,
            ),
            # backslashes, quotes and formatting signs must be parsed one at a time
            (r'[^\\\'"%{\n]+', ttype),
            (r'[\'"\\]', ttype),
            # unhandled string formatting sign
            (r"%|(\{{1,2})", ttype),
            # newlines are an error (use "nl" state)
        ];
}

with entry {
    rules = innerstring_rules(String.Single);
    print(len(rules));
    for r in rules {
        print(r[0]);
    }
}
