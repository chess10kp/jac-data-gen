"""From list of PacBio subread names, report number of ZMWs represented

    QNAME of a PacBio subread has the following convention:
    {movieName}/{holeNumber}/{qStart}_{qEnd}

    We want to count the number of holes (ZMWs), because a given hole may
    result in multiple subreads.

    Parameters
    ----------
    qnames : list
        read names of PacBio subreads

    Returns
    -------
    int
        Number of ZMWs represented by the above subreads
    """
def subreadNamesToZmwCoverage(qnames: Any) -> object {
    zmwnames = ["/".join(n.split("/")[0:2]) for n in qnames];
    zmwnames = `set(zmwnames);
    return len(zmwnames);
}