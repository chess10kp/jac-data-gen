"""Creates an html link element from the given text and url."""
def html_link(text: str, url: str) -> str {
    return '<a href="' + url + '">' + text + "</a>";
}