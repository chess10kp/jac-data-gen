"""Returns unicodes for common symbols."""
def tsym(name: str) -> str | None {
    symdict = {
        'deg': '\u00B0',
        'degree': '\u00B0',
        'degc': '\u2103',
        'degreec': '\u2103',
        'degree c': '\u2103',
        'mu': '\u00B5',
        'peclet': '\u2118',
        'permil': '\u2030',
        'permille': '\u2030',
        'per mil': '\u2030',
        'per mille': '\u2030'
    };
    try {
        out = symdict[name.lower()];
    } except KeyError {
        print(("TSYM: Symbol not known: %s" % name));
        return None;
    }
    return out;
}