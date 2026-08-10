"""
Takes two sets of pronoun slots and merges them such that the result is valid
for text that might follow text which resulted in either of the merged slot
sets.
"""
def merge_pnslots(pns1: dict[str, list[int | set[str]]], pns2: dict[str, list[int | set[str]]]) -> dict[str, list[int | set[str]]] {
    result = {};
    for pn in pns1 {
        if pns1[pn][1] == pns2[pn][1] {
            result[pn] = [max(pns1[pn][0], pns2[pn][0]), set(pns1[pn][1])];
        } else {
            result[pn] = [0, set()];
        }
    }
    return result;
}