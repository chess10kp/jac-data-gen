"""Convert the persistence diagram using duality. Here,
    add one to the dimension.
    :param diag: persistence diagram in the Gudhi format.
    :type diag: list of tuples (dim, (birth, death)).
    """
def convert_diagram_to_relative(diag: Any, max_dim: Any) -> object {
    relative_betti = {};
    for p in diag {
        dim = p[0];
        if (dim <= (max_dim - 1)) {
            relative_betti.update({(dim + 1): relative_betti.get((dim + 1), 1)});
        }
    }
    return diag;
}