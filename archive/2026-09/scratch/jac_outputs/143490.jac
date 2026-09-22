"""Returns next page of a list."""
def next_page(page_list: list[int], page: int) -> int | None {
    if page not in page_list {
        return None;
    }
    idx = page_list.index(page);
    if idx == len(page_list) - 1 {
        return None;
    }
    return page_list[idx + 1];
}