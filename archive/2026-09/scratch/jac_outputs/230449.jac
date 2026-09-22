"""Strip accents and remove interpunctuation."""
def clean_name(s: str) -> str {
    import unicodedata;
    new = s.split("-")[0];
    return ''.join(
        c
        for c in unicodedata.normalize('NFD', new)
        if unicodedata.category(c) != 'Mn'
    );
}