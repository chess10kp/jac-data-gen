import re;

"""
    Deal with lines in which spaces are used rather than tabs.
    """
def _normalize(line: str) -> str {
    SPC = re.compile(' +');
    return re.sub(SPC, '\t', line);
}