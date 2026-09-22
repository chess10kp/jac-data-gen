"""Condense multiple font weights into shorter integer equals."""
def condense_font_weight(css: str) -> str {
    return css.replace('font-weight:normal;', 'font-weight:400;').replace(
        'font-weight:bold;', 'font-weight:700;'
    );
}