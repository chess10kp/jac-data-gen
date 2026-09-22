"""Decide if a path may be a reconstruction file."""
def probably_reconstruction(file: str) -> bool {
    return file.endswith("json") and "reconstruction" in file;
}