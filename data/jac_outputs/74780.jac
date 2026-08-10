"""Expand the mask to match the tree structure."""
def handle_mask(mask: bool | list[bool], tree: list[int]) -> list[bool] {
    if isinstance(mask, bool) {
        return [mask] * len(tree);
    }
    return mask;
}