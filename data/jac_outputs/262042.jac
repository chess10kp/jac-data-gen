"""can get durations using timestamp list for inputlist
and appropriate crossvals Ti,Te,Ttot
"""
def getdiffbyindex(inputlist: list[float], indexlist: list[int]) -> list[float] {
    [
        inputlist[indexlist[i + 1]] - inputlist[indexlist[i]]
        for i in range(len(indexlist) - 1)
    ]
}