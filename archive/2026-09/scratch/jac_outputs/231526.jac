"""It extracts the tissue name from a filename."""
def _get_tissue(x: str) -> str {
    if x.endswith("-projection") {
        return x.split("spredixcan-mashr-zscores-")[1].split("-projection")[0];
    }
    return x.split("spredixcan-mashr-zscores-")[1].split("-data")[0];
}