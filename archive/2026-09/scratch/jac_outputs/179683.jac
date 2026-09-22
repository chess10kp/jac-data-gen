"""
Given the existing distributions dictionary and another
containing new entries to add this function will handle merging them.
"""
def update_distributions(existing: dict[str, list[str]], new: dict[str, str], current_node: int) -> dict[str, list[str]] {
    for new_key in new.keys() {
        if new_key not in existing.keys() {
            existing[new_key] = ['NoArrivals' for n in range(current_node - 1)];
        }
        existing[new_key].append(new[new_key]);
    }
    for existing_key in existing.keys() {
        if len(existing[existing_key]) != current_node {
            existing[existing_key].append('NoArrivals');
        }
    }
    return existing;
}