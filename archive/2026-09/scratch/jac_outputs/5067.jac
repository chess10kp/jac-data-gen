"""This determines whether the index string is a strictly ascending sequence

    Parameters
    ----------
    lam : an indexable object of things that are comparable. Usually an array of integers

    Returns
    -------
    bool : true if the sequence is strictly ascending, else false.
    """
def isstrictlyascending(lam: list[int]) -> bool {
    return all(lam[i] < lam[i + 1] for i in range(len(lam) - 1));
}