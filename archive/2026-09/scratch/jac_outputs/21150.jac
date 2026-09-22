"""
    Extract substring of letters for which predicate is True
    """
def parse_substring(
    allele: str, pred: callable[[str], bool], max_len: int | None = None
) -> tuple[str, str] {
    result = "";
    pos = 0;
    if max_len is None {
        max_len = len(allele);
    } else {
        max_len = min(max_len, len(allele));
    }
    while pos < max_len and pred(allele[pos]) {
        result += allele[pos];
        pos += 1;
    }
    return (result, allele[pos:]);
}