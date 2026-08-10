"""Deep merges dictionary object b into a."""
def merge(dst: dict[str, object] | None, src: dict[str, object] | None, path: list[str] | None = None, abort_conflict: bool = False) -> dict[str, object] | None {
    if dst is None {
        return None;
    }
    if src is None {
        return dst;
    }
    if path is None {
        path = [];
    }
    for key in src {
        if key in dst {
            if isinstance(dst[key], dict) and isinstance(src[key], dict) {
                merge(dst[key], src[key], path + [str(key)], abort_conflict);
            } elif dst[key] == src[key] {
                ;
            } elif abort_conflict {
                raise ValueError(('Conflict at %s' % '.'.join(path + [str(key)])));
            } else {
                dst[key] = src[key];
            }
        } else {
            dst[key] = src[key];
        }
    }
    return dst;
}