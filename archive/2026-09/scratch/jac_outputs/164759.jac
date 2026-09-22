""" return new color """
def get_color_file_html_new_color(scope: str, color: str, dashed: bool) -> str {
    scope_infos = "SCOPE: " + scope if scope != "" else "";
    class_added = "dashed" if dashed else "";
    return (
        "<div class=\""
        + class_added
        + "\" title=\""
        + scope_infos
        + "\" style=\"background-color:"
        + color
        + ";\"><br/><span>"
        + color
        + "</span></div>\n"
    );
}