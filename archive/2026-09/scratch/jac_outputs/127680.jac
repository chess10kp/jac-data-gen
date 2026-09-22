"""
    Turns a language name (en-us) into a locale name (en_US). If 'to_lower' is
    True, the last component is lower-cased (en_us).
    """
def to_locale(language: str, to_lower: bool = False) -> str {
    p = language.find('-');
    if p >= 0 {
        if to_lower {
            return language[:p].lower() + '_' + language[(p + 1):].lower();
        } else {
            if len(language[(p + 1):]) > 2 {
                return language[:p].lower() + '_' + language[(p + 1)].upper() + language[(p + 2):].lower();
            }
            return language[:p].lower() + '_' + language[(p + 1):].upper();
        }
    } else {
        return language.lower();
    }
}