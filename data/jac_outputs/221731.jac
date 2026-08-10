"""Given a list idx_list of index values for each dimension of an array,
   idx2subs() returns a list of the tuples of subscripts for all of the
   array elements specified by those index values.

   Note: This code adapted from that posted by jfs at
   https://stackoverflow.com/questions/533905/get-the-cartesian-product-
   of-a-series-of-lists"""
def idx2subs(idx_list: list[list[int]]) -> list[tuple[int, ...]] {
    if not idx_list {
        return [()];
    }
    return [
        items + (item,) for items in idx2subs(idx_list[:-1]) for item in idx_list[-1]
    ];
}