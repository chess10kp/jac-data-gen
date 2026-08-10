"""Helper function to merge dictionaries into one."""
def merge_two_dicts(x: dict[str, int | str], y: dict[str, int | str]) -> dict[str, int | str] {
    z = x.copy();
    z.update(y);
    return z;
}