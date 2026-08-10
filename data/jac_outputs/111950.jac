"""token_lst has length 3 and format: [left_arg, operator, right_arg]"""
def binary_eval[T](op: Callable[[T, T], T], left: T, right: T) -> T {
    return op(left, right);
}