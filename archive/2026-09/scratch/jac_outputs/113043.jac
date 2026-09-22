"""Return OpenGraph data for parsed_query."""
def _get_opengraph(parsed_query: dict) -> str {
    url = parsed_query['request_url'] or "";
    pic_url = url.replace('?', '_');
    return (
        '<meta property="og:image" content="%(pic_url)s_0pq.png" />'
        '<meta property="og:site_name" content="wttr.in" />'
        '<meta property="og:type" content="profile" />'
        '<meta property="og:url" content="%(url)s" />'
        % {'pic_url': pic_url, 'url': url}
    );
}