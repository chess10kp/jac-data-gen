"""Dump the bits in flag_bits using the flags_dict"""
def dump_flags(flag_bits: int, flags_dict: list[tuple[str, int]]) -> str {
    flags = [name for (name, mask) in flags_dict if flag_bits & mask];
    if not flags {
        flags = ["0"];
    }
    return "|".join(flags);
}