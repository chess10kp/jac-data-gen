"""Pretty format filesize/size_in_bytes into human-readable strings."""
def pretty_size(size_in_bytes: int = 0, measure: str | None = None) -> str {
    size_in_bytes = size_in_bytes or 0;
    pretty_size_map = {
        "B": size_in_bytes,
        "KB": round(size_in_bytes / 1000.0, 0),
        "KiB": round(size_in_bytes / 1024.0, 0),
        "MB": round(size_in_bytes / 1000.0 / 1000.0, 1),
        "MiB": round(size_in_bytes / 1024.0 / 1024.0, 1),
        "GB": round(size_in_bytes / 1000.0 / 1000.0 / 1000.0, 2),
        "GiB": round(size_in_bytes / 1024.0 / 1024.0 / 1024.0, 2)
    };
    if measure {
        return f'{pretty_size_map[measure]} {measure}';
    } elif pretty_size_map['GiB'] > 1 {
        return pretty_size(size_in_bytes, 'GiB');
    } elif pretty_size_map['MiB'] > 1 {
        return pretty_size(size_in_bytes, 'MiB');
    } elif pretty_size_map['KiB'] > 1 {
        return pretty_size(size_in_bytes, 'KiB');
    } else {
        return f'{size_in_bytes:,.0f} B';
    }
}