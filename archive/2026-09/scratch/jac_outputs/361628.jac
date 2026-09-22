"""Standard revcomp
    """
glob REVCOMP_TABLE = str.maketrans('ATCG', 'TAGC');

def revcomp(seq: str, ttable: dict[int, int] = REVCOMP_TABLE) -> str {
    return seq.translate(ttable)[::-1];
}