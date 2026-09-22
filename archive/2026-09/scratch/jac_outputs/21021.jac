"""Elements that are in b but not in a"""
def dict_delete(a: dict[str, object], b: dict[str, object]) -> list[str] {
    return [k for k in a if k not in b];
}