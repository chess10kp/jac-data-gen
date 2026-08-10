"""Remove all the | and the ||"""
def PreProcessScore(s: str) -> str {
    s = s.replace("|", " ");
    s = s.replace("  ", " ");
    return s;
}