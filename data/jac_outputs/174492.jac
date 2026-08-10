"""Find the index of an element in a list. The element can appear multiple times."""
def get_all_indices(element: object, alist: list[object]) -> list[int] {
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