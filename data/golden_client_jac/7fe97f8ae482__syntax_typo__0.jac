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
    # >>>HOLE id="lib_innerstring_rules" instruction="Return a list of Pygments regex rule tuples for highlighting a plain (non-f) string body. In order: (1) a rule matching old-style percent-format specifiers (the %(name) flags width .precision length conversion form) tagged String.Interpol; (2) a rule matching new-style brace-format fields (an open brace, an optional field name with dotted-attribute or bracket-index accessors, an optional bang conversion of s/r/a, an optional colon format-spec, then a close brace) also tagged String.Interpol; (3) a rule matching one or more characters that are none of backslash, single quote, double quote, percent, open-brace or newline, tagged with the passed-in ttype; (4) a rule matching a single backslash or quote character tagged ttype; (5) a rule matching a lone percent or one-or-two open-braces tagged ttype. Build the percent and brace patterns by concatenating raw-string fragments."
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
    # <<<HOLE
}

with entry {
    rules = innerstring_rules(String.Single);
    print(len(rules));
    for r in rules {
        print(r[0]);
    }
}
