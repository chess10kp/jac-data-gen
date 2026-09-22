"""Extract discourse relation on different level."""
def extractrelation(s: str, level: int = 0) -> str {
    items = s.lower().split('-');
    if items[0] == 'same' {
        rela = '_'.join(items[:2]);
    } else {
        rela = items[0];
    }
    return rela;
}