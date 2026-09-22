""" Return the index to the next element (compared to the element
  with index "index") in aList, or 0 if it already is the last one.
  Useful to make a list of loop.
  """
def next(aList: Any, index: Any) -> object {
    return ((index + 1) % len(aList));
}