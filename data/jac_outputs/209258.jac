"""String to Boolean."""
def str2bool(v: str) -> bool {
    return v.lower() in ("true", "t", "1");
}