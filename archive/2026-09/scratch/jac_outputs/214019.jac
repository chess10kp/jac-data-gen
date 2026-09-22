"""Build Open Library urls."""
def build_openlibrary_urls(isbn: Any) -> object {
    url = "https://covers.openlibrary.org/b/isbn";
    return {
        "is_placeholder": False,
        "small": "{url}/{isbn}-S.jpg".format(url=url, isbn=isbn),
        "medium": "{url}/{isbn}-M.jpg".format(url=url, isbn=isbn),
        "large": "{url}/{isbn}-L.jpg".format(url=url, isbn=isbn)
    };
}