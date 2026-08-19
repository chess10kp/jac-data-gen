import from pygments.token { String }

def innerstring_rules(ttype: any) -> list {
    return [
        (r"%[sdif]", String.Interpol),
        (r'[^\\\'"%{\n]+', ttype),
    ];
}
