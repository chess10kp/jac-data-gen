"""Scroll the package list further one page."""
def key_right(
    pos: int, page: int, page_len: int, pages: int, total_pkgs: int
) -> tuple[int, int] {
    if page == pages {
        ;
    } elif total_pkgs < page_len + page_len * (page + 1) {
        page += 1;
        pos = total_pkgs;
    } else {
        page += 1;
        pos += page_len;
    }
    return (pos, page);
}