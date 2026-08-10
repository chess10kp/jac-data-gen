"""Filter [src,tgt] tuple from input list of pairs if either element is empty.

  Args:
    src_tgt_pairs: list of (src,tgt) pairs

  Returns:
    subset of input pair list for which all elements are non-empty
  """
def throw_empty_pairs(src_tgt_pairs: Any) -> object {
    return [
        x
        for x in src_tgt_pairs
        if (x[0] and x[1])
    ];
}