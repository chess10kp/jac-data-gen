"""
  Build an index for a sequence of items. Assumes
  that the items in the sequence are unique.
  """
def index(seq: list[str | int]) -> dict[str | int, int] {
    return dict((k, v) for (v, k) in enumerate(seq));
}