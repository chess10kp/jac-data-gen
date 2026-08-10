"""Validates the floating point inputs."""
def is_valid_positive_float(in_val: str) -> bool {
    try {
        _ = float(in_val);
    } except Exception {
        return False;
    }
    if float(in_val) < 0.0 {
        return False;
    }
    return True;
}