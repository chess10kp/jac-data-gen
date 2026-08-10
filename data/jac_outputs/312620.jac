"""
    This function switches from a specific {tag} to a specific
    markdown link syntax

    Example:
    <a href=URL>CAPTION</a> => [CAPTION](URL)
    """
def link_handler(tag: str, post_html: str) -> str {
    old_tag = tag;
    close_tag = "</{0}>".format(tag);
    tag = "<{0}".format(tag);
    start = post_html.find(tag);
    end = post_html.find(close_tag) + len(close_tag);
    link_html = post_html[start:end];
    link_markdown = "";
    link = "";
    caption = "";
    caption = link_html[link_html.find(">") + 1:link_html.find("</a>")];
    if link_html.find("href=") >= 0 {
        link = link_html[link_html.find("href=") + 6:link_html.find("\" data-href=")];
    }
    if not caption {
        caption = link;
    }
    if link {
        link_markdown = "[{0}]({1})".format(caption, link);
    }
    post_html = post_html[:start] + link_markdown + post_html[end:];
    if post_html.find(tag) >= 0 {
        post_html = link_handler(old_tag, post_html);
    }
    return post_html;
}