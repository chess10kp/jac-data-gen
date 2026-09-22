"""Computes the average translation and rotation within a sequence (across subsequences of diff lengths)."""
def getStats(err: Any) -> object {
    t_err = 0;
    r_err = 0;
    for e in err {
        t_err += e[2];
        r_err += e[1];
    }
    t_err /= float(len(err));
    r_err /= float(len(err));
    return (t_err, r_err);
}