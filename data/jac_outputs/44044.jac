"""Split an hdf path of the form path.hdf/group, where the group part is optional, into the path and the group parts."""
def split_hdf_path(fname: str, subgroup: str | None = None) -> tuple[str, str | None] {
    for suf in [".hdf", ".h5"] {
        (name, _, group) = fname.rpartition(suf);
        if not name {
            continue;
        }
        name += suf;
        if not group {
            return (name, subgroup);
        } elif group[0] == "/" {
            group_path: str = group[1:];
            if subgroup {
                group_path = group_path + "/" + subgroup;
            }
            return (name, group_path);
        }
    }
    raise ValueError("Not an hdf path");
}