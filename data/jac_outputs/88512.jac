""" entry-wise average of a list of matrices """
def avgout(vallist: Any) -> object {
    r = len(vallist);
    A = 0;
    if (r > 0) {
        for B in vallist {
            A += (1.0 / r) * B;
        }
    }
    return A;
}