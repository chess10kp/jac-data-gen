"""
    Identifies the position of duplicated sequences
    """
def list_duplicates_of(seq: list[int], item: int) -> list[int] {
    start_at = -1;
    locs = [];
    while True {
        try {
            loc = seq.index(item, start_at + 1);
        } except ValueError {
            break;
        } else {
            locs.append(loc);
            start_at = loc;
        }
    }
    return locs;
}