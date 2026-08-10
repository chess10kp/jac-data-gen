"""Get index of TM helix given a residue position
Return -1 if iRes is not within TM region
"""
def GetTMIndex(iRes: int, posTM: list[tuple[int, int]]) -> int {
    for (i, (b, e)) in enumerate(posTM) {
        if iRes >= b and iRes < e {
            return i;
        }
    }
    return -1;
}