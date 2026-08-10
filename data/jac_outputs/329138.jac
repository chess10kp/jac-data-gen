"""
  Slightly improved insertion sort

  Complexity: O(n ** 2)

  """
def insertion_sort2(L: list[int]) -> list[int] {
    for i in range(len(L)) {
        key = L[i];
        j = i - 1;
        while j > -1 and L[j] > key {
            L[j + 1] = L[j];
            j -= 1;
        }
        L[j + 1] = key;
    }
    return L;
}