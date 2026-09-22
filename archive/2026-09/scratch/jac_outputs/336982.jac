"""Return the number of argument combinations (and thus the number of corresponding ids)"""
def num_ids_from_args(arg_ranges: Any) -> object {
    import from functools { reduce }
    import operator;
    return reduce(operator.mul, [len(r) for r in arg_ranges], 1);
}