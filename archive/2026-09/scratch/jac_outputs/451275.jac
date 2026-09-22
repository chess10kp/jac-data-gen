"""Return all paths of pointing relations starting from src_id."""
def __walk_chain(rel_dict: dict[str, set[str]], src_id: str) -> list[list[str]] {
    paths_starting_with_id = [];
    for target_id in rel_dict[src_id] {
        if target_id in rel_dict {
            for tail in __walk_chain(rel_dict, target_id) {
                paths_starting_with_id.append([src_id] + tail);
            }
        } else {
            paths_starting_with_id.append([src_id, target_id]);
        }
    }
    return paths_starting_with_id;
}