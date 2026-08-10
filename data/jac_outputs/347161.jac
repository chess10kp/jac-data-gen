"""Extract cells and total order of the cells

    Parameters
    ----------
    X: cell complex. List of dictionaries, one per dimension d. The size of the dictionary
        is the number of d-cells. The dictionary's keys are sets corresponding to the name of the cells in XQ. The
        dictionary's values are the indexes of the cells in the boundary,and chain homotopy matrices.
    -------
    tot_order: cells complex X stored as one dictionary. The dictionary's keys are sets corresponding to the name of the cells in X. The
        dictionary's values are the indexes of the cells in the chain homotopy matrices phi and psi.
    """
def extract_total_order(X: list[dict[object, object]]) -> dict[object, int] {
    tot_order = dict();
    k = 0;
    for d in range(len(X)) {
        for cell in X[d].keys() {
            tot_order[cell] = k;
            k += 1;
        }
    }
    return tot_order;
}