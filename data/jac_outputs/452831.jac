"""Swap two positions in a list at given indexes."""
def swap(heights_list: list[int], index01: int, index02: int) -> list[int] {
    (heights_list[index01], heights_list[index02]) = (
        heights_list[index02],
        heights_list[index01]
    );
    return heights_list;
}