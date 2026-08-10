"""Rekeys a batch using key_map.

key_map specifies new_key: old_key pairs.
"""
def rekey(batch: dict[str, list], key_map: dict[str, str]) -> dict[str, list] {
    {key: batch[value] for (key, value) in key_map.items()}
}