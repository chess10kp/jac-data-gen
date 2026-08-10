"""Count list nodes and return sum."""
def count_list_nodes(taxonomy: dict[str, dict]) -> int {
    count = 0;
    keys = [x for x in list(taxonomy.keys()) if x != "data"];
    for i in keys {
        if set(taxonomy[i]) == set(list({"data"})) {
            if i == keys[-1] {
                count += 1;
                return count;
            }
            count += 1;
        } else {
            count += count_list_nodes(taxonomy[i]);
        }
    }
    return count;
}