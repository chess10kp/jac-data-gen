"""Clear prefix and some suffixes for name."""
def _clean_name(net: bool, name: str) -> str {
    if name.endswith("_fwd_output") {
        name = name[:-len("_fwd_output")];
    } elif name.endswith("_fwd") {
        name = name[:-len("_fwd")];
    } elif name.endswith("_output") {
        name = name[:-len("_output")];
    }
    return name;
}