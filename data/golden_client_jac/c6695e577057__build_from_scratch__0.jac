import from pygments.token { String }

def fstring_rules(ttype: any) -> list {
    return [
        (r"\{", String.Interpol),
        (r"\}", String.Interpol),
        (r'[^{}]+', ttype),
    ];
}
