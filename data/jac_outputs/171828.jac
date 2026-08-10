"""Returns a list of index values that match accepted values.

acceptedvaluelist should be entered as a list.
[1,-1] is suggested for breathing analysis.
"""
def getindexlist(inputlist: list[int], acceptedvaluelist: list[int]) -> list[int] {
    return [i for (i, x) in enumerate(inputlist) if x in acceptedvaluelist];
}