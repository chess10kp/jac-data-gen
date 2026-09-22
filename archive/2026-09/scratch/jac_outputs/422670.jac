"""Helper function to remove any blank space from a string."""
def remove_whitespace(x: str) -> str {
    try {
        x = "".join(x.split());
    } except Exception {
        ;
    }
    return x;
}