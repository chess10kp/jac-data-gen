glob PAGE_SIZE = 1980;

"""Simple generator that paginates text."""
def paginate(text: str) -> list[str] {
    last = 0;
    pages = [];
    appd_index = 0;
    curr = 0;
    for curr in range(0, len(text)) {
        if curr % PAGE_SIZE == 0 {
            pages.append(text[last:curr]);
            last = curr;
            appd_index = curr;
        }
    }
    if appd_index != len(text) - 1 {
        pages.append(text[last:curr]);
    }
    return list(filter(lambda (a: str) { a != ''; }, pages));
}