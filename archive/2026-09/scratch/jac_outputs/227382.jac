"""Convert the string permission into a dict to unpack for insert_permission."""
def parse_permission(perm: str) -> dict[str, str | bool] {
    perm_dict: dict[str, str | bool] = {};
    parts = perm.split("|");
    for part in parts {
        if "@" in part {
            perm_dict["value"] = part;
            perm_dict["perm_type"] = "user";
        } elif "." in part {
            perm_dict["value"] = part;
            perm_dict["perm_type"] = "domain";
        } elif part == "anyone" {
            perm_dict["perm_type"] = "anyone";
        } elif part in ["grp", "group"] {
            perm_dict["perm_type"] = "group";
        } elif part in ["owner", "writer", "reader"] {
            perm_dict["role"] = part;
        } elif part in ["no", "false"] {
            perm_dict["notify"] = False;
        } elif part == "link" {
            perm_dict["with_link"] = True;
        }
        perm_dict["role"] = perm_dict.get("role", "reader");
    }
    return perm_dict;
}