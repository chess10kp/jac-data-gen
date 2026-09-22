"""
    :return: the html with the corresponding links from the entities
    """
def replace_urls_from_entinies(html: str, urls: list[dict[str, str]]) -> str {
    for url in urls {
        link = '<a href="%s">%s</a>' % (url['url'], url['display_url']);
        html = html.replace(url['url'], link);
    }
    return html;
}