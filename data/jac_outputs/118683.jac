"""Add new_dep to dep_list if not already present."""
def add_to_list_if_new(dep_list: list[str], new_dep: str) -> list[str] {
    if new_dep not in dep_list {
        dep_list.append(new_dep);
    }
    return dep_list;
}