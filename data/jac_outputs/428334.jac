"""Split a list.

Recipe From http://code.activestate.com/recipes/425397/ (Modified to not return blank values)"""
def SplitSequence(seq: list[int], size: int) -> list[list[int]] {
    newseq: list[list[int]] = [];
    splitsize = (1.0 / size) * len(seq);
    for i in range(size) {
        newseq.append(
            seq[int(round(i * splitsize)):int(round((i + 1) * splitsize))]
        );
    }
    return [x for x in newseq if x];
}