"""HTML snippet: span with class 'colorspot' and `htmlcolorcode` as background color."""
def color_spot(htmlcolorcode: str, text: str | None = None) -> str {
    if text is None {
        text = htmlcolorcode;
    }
    return '<span class="colorspot" style="background-color:%s;">&nbsp;&nbsp;&nbsp;</span>&nbsp;%s' % (htmlcolorcode, text);
}