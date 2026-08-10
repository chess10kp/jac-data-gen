"""One or more page numbers or range of numbers, such as 42-111 or 7,41,73-97
       or 43+ (the `+' in this last example indicates pages following that don't
       form a simple range). To make it easier to maintain Scribe-compatible
       databases, the standard styles convert a single dash (as in 7-33) to the
       double dash used in TEX to denote number ranges (as in 7-33)."""
def formatPages(pages: str) -> str {
    return pages;
}