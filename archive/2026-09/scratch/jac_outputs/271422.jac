"""
Find the index of an element in a list. The element can appear multiple times.
"""
def getAllIndices(element: str, alist: list[str]) -> list[int] {
    result = [];
    offset = -1;
    while True {
        try {
            offset = alist.index(element, offset + 1);
        } except ValueError {
            return result;
        }
        result.append(offset);
    }
}