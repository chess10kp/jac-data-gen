"""Return time stored in ar_filename, or 0.0 if it does not exist."""
def GetPersistTime(ar_filename: str) -> float {
    try {
        with open(ar_filename) as f {
            return float(f.read());
        }
    } except (IOError, ValueError) {
        return 0.0;
    }
}