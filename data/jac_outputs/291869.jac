"""
      diff(a:iterable, b: iterable)
          a - b; elements in a but not in b

      args:
          a: iterable, b: iterable => eg: [1,2,3], [1]
      return:
          a list of (a - b)        => eg: [2,3]
    """
def diff(a: list[int], b: list[int]) -> list[int] {
    sb = set(b);
    return [e for e in a if e not in sb];
}