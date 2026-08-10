"""Split version string into numeric components."""
def split_ver_str(ver_str: str) -> list[int] {
    ver_list: list[int] = [];
    for c in ver_str.split(".")[0:3] {
        if not c.isdecimal() {
            raise RuntimeError(
                "Malformed version string '{}'. "
                "Component '{}' is not an integer.".format(ver_str, c)
            );
        }
        ver_list.append(int(c));
    }
    return ver_list;
}