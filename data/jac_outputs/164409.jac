"""Flatten lists to fit the requrests multipart form data format."""
def format_multipart(props: dict[str, object]) -> tuple[tuple[str, object], ...] {
    ret: list[tuple[str, object]] = [];
    for (k, v) in props.items() {
        if type(v) == list {
            for item in (v as list[object]) {
                ret.append((k, item));
            }
        } else {
            ret.append((k, v));
        }
    }
    return tuple(ret);
}