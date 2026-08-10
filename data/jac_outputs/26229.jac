"""Check if the netmask is valid.

Return mask as string in the range [0, 32] or False if not valid.
"""
def validate_mask(mask: str | None) -> str | bool {
    if not mask {
        return False;
    }
    mask = mask.strip();
    if mask.isdigit() and int(mask) >= 0 and int(mask) <= 32 {
        return mask;
    }
    return False;
}