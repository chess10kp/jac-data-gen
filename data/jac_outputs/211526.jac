"""Format state attributes"""
def format_attribute(attr: str) -> str {
    res = attr.replace("-", " ");
    res = res.capitalize();
    res = res.replace(" ip ", " IP ");
    res = res.replace(" mac ", " MAC ");
    res = res.replace(" mtu", " MTU");
    return res;
}