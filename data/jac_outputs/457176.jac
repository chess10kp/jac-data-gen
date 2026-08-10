"""Compare versions the way chrome does."""
def cmpversion(a: str, b: str) -> bool {
    def split_version(v: str) -> list[str] | tuple[str, str] {
        if '.' in v {
            return v.split('.', 1);
        }
        if '_' in v {
            return v.split('_', 1);
        }
        return (v, '0');
    }
    (a_maj, a_min) = split_version(a);
    (b_maj, b_min) = split_version(b);
    if a_maj == b_maj {
        return cmpversion(a_min, b_min);
    }
    return int(a_maj) > int(b_maj);
}