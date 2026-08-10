"""Convert PROJ.4 compatible string definition to dict.

Note: Key only parameters will be assigned a value of `True`.
"""
def proj4_str_to_dict(proj4_str: str) -> dict[str, str | bool] {
    pairs = (x.split('=', 1) for x in proj4_str.replace('+', '').split(" "));
    return dict((x[0], x[1] if len(x) == 2 else True) for x in pairs);
}