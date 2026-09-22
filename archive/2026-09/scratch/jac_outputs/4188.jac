"""List of indices into the RTTOV chanprof(:) array corresponding to the chanlist.
NB This assumes you've checked the chanlist against chanprof already.
"""
def getChanprofIndex(chanprof: list[list[int]], profile: int, chanList: list[int]) -> list[int] {
    ilo = sum(len(x) for x in chanprof[:profile - 1]);
    return [ilo + chanprof[profile - 1].index(c) for c in chanList];
}