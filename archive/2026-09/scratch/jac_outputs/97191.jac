"""Get minimum values for each index range pair from input list."""
def getminby2index(inputlist: list[float], index1: list[int], index2: list[int]) -> list[float] {
    return [min(inputlist[index1[i]:index2[i]]) for i in range(len(index1))];
}