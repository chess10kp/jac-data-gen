"""HACK A DID ACK - please delete me when cleaning up."""
def guess_max_depth(map_or_seq: dict[str, object] | list[dict[str, object]]) -> int {
    if isinstance(map_or_seq, dict) {
        d = map_or_seq as dict[str, object];
        return 1 + max((guess_max_depth(nested as dict[str, object] | list[dict[str, object]]) for nested in d.values()), default=0);
    } elif isinstance(map_or_seq, list) {
        first = (map_or_seq as list[dict[str, object]])[0];
        return 1 + max((guess_max_depth(nested as dict[str, object] | list[dict[str, object]]) for nested in first.values()), default=0);
    }
    return 0;
}