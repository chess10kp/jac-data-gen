"""Returns a marker filename for an external repository."""
def marker_name(name: str) -> str {
    return "@{}.marker".format(name.replace("//external:", ""));
}