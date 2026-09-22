"""Get User Manual HTML tag."""
def get_book_tag(tool_name: str, category: str) -> str {
    prefix = "https://www.whiteboxgeo.com/manual/wbt_book/available_tools";
    url = "{}/{}.html#{}".format(prefix, category, tool_name);
    return "<a href='{}' target='_blank'>WhiteboxTools User Manual</a>".format(url);
}