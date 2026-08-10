"""Prepare metainfo for package."""
def prepare_package(date: str, metainfo: dict[str, str | list | dict[str, str]] | None = None) -> dict[str, str | list | dict[str, str]] {
    base = {
        'publishedDate': date,
        'releases': [],
        'publisher': {'name': '', 'scheme': '', 'uri': ''}
    };
    if metainfo {
        base.update(metainfo);
    }
    return base;
}