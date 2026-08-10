"""
Slices off the passed proportion of items from BOTH ends of the passed
list. Assumes list is sorted by magnitude.
"""
def ltrimboth(l: list[float], proportiontocut: float) -> list[float] {
    lowercut = int(proportiontocut * len(l));
    uppercut = len(l) - lowercut;
    return l[lowercut:uppercut];
}