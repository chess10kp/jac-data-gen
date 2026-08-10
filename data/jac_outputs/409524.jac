"""Return a valid bib.series string."""
def bibser2bibstr(bib: str = '', ser: str = '') -> str {
    ret = bib;
    if ser != '' {
        ret += '.' + ser;
    }
    return ret;
}