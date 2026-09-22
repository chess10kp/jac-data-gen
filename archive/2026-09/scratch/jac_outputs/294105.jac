"""Expands a uid-pool definition to a list of uids.

  @param uid_pool: a list of integer pairs (lower, higher range boundaries)
  @return: a list of integers

  """
def ExpandUidPool(uid_pool: list[tuple[int, int]]) -> list[int] {
    uids = set();
    for (lower, higher) in uid_pool {
        uids.update(range(lower, higher + 1));
    }
    return list(uids);
}