"""
    Get inside/outside state for the loop before the current TM helix
    Input:
        topo        topology sequence of the protein
        begin_TM    sequence position at the beginning of the TM helix
                    (begin_TM, end_TM) defines the location of the TM helix
                    in the sequence
    Output:
        state       'i' or 'o', if all gaps, return empty string ""
    """
def Get_IOState_upstream(topo: str, begin_TM: int) -> str {
    i = begin_TM;
    while i >= 0 {
        if topo[i] in ('i', 'o') {
            return topo[i];
        }
        i -= 1;
    }
    return '';
}