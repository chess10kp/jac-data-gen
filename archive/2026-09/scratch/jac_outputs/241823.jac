"""
    Convert `t` from midi tics to beats given beat division `div`

    Parameters
    ----------

    t : number

    div : number

    Returns
    -------
    number
    """
def tic2beat(t: Any, div: Any) -> object {
    return (t / float(div));
}