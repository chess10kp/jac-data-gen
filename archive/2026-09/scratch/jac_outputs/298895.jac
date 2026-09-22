"""True if the filename represents a p4 program that should fail."""
def is_err(p4filename: str) -> bool {
    return "_errors" in p4filename;
}