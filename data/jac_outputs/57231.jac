"""split list"""
def split_list(alist: list[int], wanted_parts: int = 1) -> list[list[int]] {
    length = len(alist);
    return [
        alist[i * length // wanted_parts:(i + 1) * length // wanted_parts]
        for i in range(wanted_parts)
    ];
}