obj IndexAxis {
    def get_loc(key: str) -> int;
}

"""Create a filtered indexer that doesn't have any missing indexers."""
def convert_from_missing_indexer_tuple(indexer: list[dict[str, str] | int], axes: list[IndexAxis]) -> tuple[int, ...] {
    def get_indexer(i: int, idx: dict[str, str] | int) -> int {
        if isinstance(idx, dict) {
            return axes[i].get_loc(idx['key']);
        }
        return idx as int;
    }
    return tuple([get_indexer(i, idx) for (i, idx) in enumerate(indexer)]);
}