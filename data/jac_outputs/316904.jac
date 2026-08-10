"""Wrapper for binary operator functions.

  """
def _WrapBinaryOp(
    op_fn: Any, retrieval_fn: Any, value: Any, ctx: Any, item: Any
) -> object {
    return op_fn(retrieval_fn(ctx, item), value);
}