"""Check if doc has content."""
def doc_has_content(doc: dict[str, str]) -> bool {
    len_title = len(doc['title'].split());
    len_content = len(doc['content'].split());
    return len_content - len_title > 50;
}