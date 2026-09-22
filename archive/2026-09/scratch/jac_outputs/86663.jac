"""Returns the next tag ID given the list of tags"""
def nextTagID(tags: list[dict[int | str, int]]) -> int {
    0 if not tags else sorted(tags, key=lambda (x: dict[int | str, int]) { x['id']; })[-1][0] + 1
}