"""Checks if two behavior ID strings are the same (e.g. 'fd' vs. 'fd_r')."""
def is_same_behavior_id_str(behavior_id_str_1: str, behavior_id_str_2: str) -> bool {
    return behavior_id_str_1.startswith(behavior_id_str_2)
        or behavior_id_str_2.startswith(behavior_id_str_1);
}