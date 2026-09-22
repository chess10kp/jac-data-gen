import re;

"""Remove periods from text."""
def stripperiods(aText: str) -> str {
    aText = re.sub(r"\.", " ", aText);
    return re.sub(" {2,}", " ", aText);
}