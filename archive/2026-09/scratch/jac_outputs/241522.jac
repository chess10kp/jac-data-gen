"""Replace `:0 0 0 0;`, `:0 0 0;` etc. with `:0;`."""
def condense_multidimensional_zeros(css: str) -> str {
    css = css.replace(":0 0 0 0;", ":0;");
    css = css.replace(":0 0 0;", ":0;");
    css = css.replace(":0 0;", ":0;");
    css = css.replace("background-position:0;", "background-position:0 0;");
    return css;
}