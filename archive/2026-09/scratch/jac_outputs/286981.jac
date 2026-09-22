"""Find manual FOVs whose names do not match their corresponding auto FOV."""
def find_manual_auto_name_mismatches(manual_to_auto_map: dict[str, str]) -> list[tuple[str, str]] {
    return [(k, v) for (k, v) in manual_to_auto_map.items() if k != v];
}