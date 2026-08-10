"""For a specific operation (mismatch, match, insertion, deletion... see above)
return occurrences and index in the alignment."""
def parse_cigar(cigarlist: list[tuple[int, int]], ope: int) -> list[list[int]] {
    tlength = 0;
    coordinate: list[list[int]] = [];
    oplist = (0, 1, 2, 7, 8);
    for (operation, length) in cigarlist {
        if operation == ope {
            coordinate.append([length, tlength]);
        }
        if operation in oplist {
            tlength += length;
        }
    }
    return coordinate;
}