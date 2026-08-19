import from pygments.token { String }

def fstring_rules(ttype: any) -> list;

impl fstring_rules {
    return [
            (r"\}", String.Interpol),
            (r"\{", String.Interpol, "expr-inside-fstring"),
            (r'[^\\\'"{}\n]+', ttype),
            (r'[\'"\\]', ttype),
        ];
}
