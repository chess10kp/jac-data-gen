"""It returns given vocal with grave or acute accent"""
def getAccentedVocal(vocal: str, acc_type: str = "g") -> str {
    vocals = {
        'a': {'g': '\xe0', 'a': '\xe1'},
        'e': {'g': '\xe8', 'a': '\xe9'},
        'i': {'g': '\xec', 'a': '\xed'},
        'o': {'g': '\xf2', 'a': '\xf3'},
        '': {'g': '\xf9', 'a': '\xfa'}
    };
    return vocals[vocal][acc_type];
}