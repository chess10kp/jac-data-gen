"""Returns a key for given value or None"""
def dict_value2key(mydict: dict[str, int | str] | None, value: int | str) -> str | None {
    if mydict is None {
        return None;
    }
    try {
        return list(mydict.keys())[list(mydict.values()).index(value)];
    } except ValueError {
        return None;
    }
}