"""Determine what level the employment sector NAICS code represents."""
def _naics_level(code: str) -> int {
    codestr = code.split("-")[-1];
    return len(codestr) - codestr.count("0") + 2;
}