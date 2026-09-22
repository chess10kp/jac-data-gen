"""Return a consistent sex notation (male, female)."""
def get_sex(sex: str) -> str {
    lowered = sex.lower();
    if lowered == 'm' {
        return 'male';
    }
    if lowered == 'f' {
        return 'female';
    }
    return lowered;
}