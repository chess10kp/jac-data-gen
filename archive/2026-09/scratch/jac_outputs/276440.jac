"""
Transpose a given matrix using Zip. A 1x4 matrix becomes a 4x1 matrix
"""
def transpose_2d(a: list[list]) -> list[list] {
  if `type(a) != list {
    raise TypeError('Error xm10: Incorrect type, matrices must be of type "list"');
  }
  l = len(a[0]);
  for row in a {
    if len(row) != l {
      raise Exception("Error xm11: Row lengths do not match");
    }
  }
  return list(map(list, zip(*a)));
}