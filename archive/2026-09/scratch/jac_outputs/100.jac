"""Compare elements that have changed between prev_hash_dict and current_hash_dict.

Check if any elements have been added, removed or modified.
"""
def compare_elements(prev_hash_dict: dict[str, str], current_hash_dict: dict[str, str]) -> dict[str, str] {
    changed = {};
    for key in prev_hash_dict {
        elem = current_hash_dict.get(key, '');
        if elem == '' {
            changed[key] = 'deleted';
        } elif elem != prev_hash_dict[key] {
            changed[key] = 'changed';
        }
    }
    for key in current_hash_dict {
        elem = prev_hash_dict.get(key, '');
        if elem == '' {
            changed[key] = 'added';
        }
    }
    return changed;
}