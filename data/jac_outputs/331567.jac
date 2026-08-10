""" Changes a list of np.int64 type to plain int type.
    Because it seems sqlite is changing np.intt64 to byte type??
    """
def npint2int(npints: list[int]) -> list[int] {
    return [int(npint) for npint in npints];
}