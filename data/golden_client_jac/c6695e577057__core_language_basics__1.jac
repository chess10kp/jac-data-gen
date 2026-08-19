"""RL driver (pure-lib): source_lexer.fstring_rules (build f-string highlight rules).

Origin: this_is_jac/source_lexer.jac (the fstring_rules logic, isolated from the Pygments
RegexLexer/token-table machinery). Deterministic: the body returns a fixed list of
regex-string + token-type rule tuples (some with a state-transition name) built from constant
raw-string fragments, so the projection (rule count + each regex pattern) is identical every
run. The marked body is the unit the policy must regenerate; the with entry block exercises it
on a fixed token type and prints a deterministic projection.
"""

import from pygments.token { String }

"""Interpolation rules for an f-string body (a `{` opens a nested expr state)."""
def fstring_rules(ttype: any) -> list {
    # >>>HOLE id="lib_fstring_rules" instruction="Return a list of Pygments regex rule tuples for an f-string body. In order: (1) a rule matching a single closing brace tagged String.Interpol; (2) a rule matching a single opening brace tagged String.Interpol that also transitions into the nested expression state named expr-inside-fstring; (3) a rule matching one or more characters that are none of backslash, single quote, double quote, open-brace, close-brace or newline, tagged with the passed-in ttype; (4) a rule matching a single quote or backslash character tagged ttype."
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
    # <<<HOLE
}

with entry {
    rules = fstring_rules(String.Double);
    print(len(rules));
    for r in rules {
        print(r[0]);
    }
}
