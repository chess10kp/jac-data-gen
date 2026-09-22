"""Returns a list."""
def resultlist_reader(response: list[dict[str, list[dict[str, str]]]], all_unicode: bool = False) -> list[str | None] {
    links = [];
    def get_self(links: list[dict[str, str]]) -> str | None {
        for link in links {
            if link['rel'] == "self" {
                return link['uri'];
            }
        }
    }
    for result in response {
        links.append(get_self(result['links']));
    }
    return links;
}