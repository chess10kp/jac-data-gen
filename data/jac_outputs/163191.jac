"""
      tail(lst: list)
          1 to len of a list

      args:
          a list => eg: [1,2,3]
      return:
          a list => [2,3]
    """
def tail(lst: Any) -> object {
    return lst[1:];
}