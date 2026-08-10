"""In: RGB color array
    Out: HEX string"""
def RGB2HEX(color: list[int | float]) -> str {
    return "#{:02x}{:02x}{:02x}".format(int(color[0]), int(color[1]), int(color[2]));
}