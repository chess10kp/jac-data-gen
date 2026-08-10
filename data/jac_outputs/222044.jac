"""Return object directory prefix (first two chars of object hash)."""
def get_object_dir_prefix(objhash: str) -> str {
    return objhash[0:2] + "/";
}