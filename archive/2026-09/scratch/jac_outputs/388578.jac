"""
**Chunks a list into a partition of specified size.**
"""
def chunkIt(seq: list[object], num: int) -> list[list[object]] {
    out: list[list[object]] = [];
    last = 0.0;
    while last < len(seq) {
        if int(last + num) > len(seq) {
            break;
        } else {
            out.append(seq[int(last):int(last + num)]);
            last += num;
        }
    }
    return out;
}