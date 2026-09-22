"""
    Given a grid of points xi (sorted smallest to largest) find in
    which interval the point x sits.  Returns i, where x \in [ xi[i],xi[i+1] ].
    Raise ValueError if x is not inside the grid.
    """
def interval_idx(x: Any, xi: Any) -> object {
    assert ((x >= xi[0]) and (x <= xi[-1])) , ValueError(
        ('x=%g not in [%g,%g]' % (x, xi[0], xi[-1]))
    );
    for i in range((len(xi) - 1)) {
        if ((xi[i] <= x) and (x <= xi[(i + 1)])) {
            return i;
        }
    }
}