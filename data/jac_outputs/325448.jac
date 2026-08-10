"""Generate common filters for any list request."""
def common_filters(
    limit: int | None = None,
    sort_key: str | None = None,
    sort_dir: str | None = None,
    marker: str | None = None
) -> list[str] {
    filters = [];
    if isinstance(limit, int) and limit > 0 {
        filters.append('limit=%s' % limit);
    }
    if sort_key is not None {
        filters.append('sort_key=%s' % sort_key);
    }
    if sort_dir is not None {
        filters.append('sort_dir=%s' % sort_dir);
    }
    if marker is not None {
        filters.append('marker=%s' % marker);
    }
    return filters;
}