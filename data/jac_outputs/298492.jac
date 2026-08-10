"""
    Return a dict of {state: action} pairs describing what can be reached from the
    (x, y) state, and how. Note, tuple is hashable.
    """
def successors(x: Any, y: Any, X: Any, Y: Any) -> object {
    assert ((x <= X) and (y <= Y));
    return {
        (0, (y + x)) if ((y + x) <= Y) else ((x - (Y - y)), (y + (Y - y))): 'X->Y',
        ((x + y), 0) if ((x + y) <= X) else ((x + (X - x)), (y - (X - x))): 'X<-Y',
        (X, y): 'fill X',
        (x, Y): 'fill Y',
        (0, y): 'empty X',
        (x, 0): 'empty Y'
    };
}