"""Concatenates multiple expressions into a single expression by using the
    barrier operator.
    """
def concat_multi_expr(*expr_args: int) -> int | None {
    me = None;
    for e in expr_args {
        me = (me | e) if me else e;
    }
    return me;
}