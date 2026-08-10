"""Reset op_debug_level to 0 when level is 3 or 4."""
def reset_op_debug_level_in_soc_info(level: str) -> str {
    if level in ("3", "4") {
        level = "0";
    }
    return level;
}