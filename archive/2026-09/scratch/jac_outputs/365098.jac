"""Oryza_sativa -> osat"""
def shorten(name: str) -> str {
    split = name.lower().split("_");
    return split[0][0] + split[1][:3];
}