"""Count the insertions in the read using the CIGAR string."""
def _parse_cigar(cigartuples: Any) -> object {
    return sum(
        [
            item[1]
            for item in cigartuples
            if (item[0] == 1)
        ]
    );
}