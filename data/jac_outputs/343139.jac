"""
  Finds the smallest positive integer not in array.
  The smallest possible answer is 1.
  """
def solution(array: list[int]) -> int {
    i = 1;
    visited = [];
    for value in array {
        visited.append(value);
        if value == i {
            while True {
                value += 1;
                if value not in visited {
                    break;
                }
            }
            i = value;
        }
    }
    return i;
}