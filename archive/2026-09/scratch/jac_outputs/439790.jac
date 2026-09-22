"""Parses an output pattern"""
def parseOutputPattern(outpat: str) -> tuple[str, str, str] {
    (r, g, b) = outpat.strip().lower().split(',');
    return (r, g, b);
}