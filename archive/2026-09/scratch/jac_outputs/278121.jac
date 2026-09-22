""" Extract the pin names from the vector line """
def get_pins(line: str) -> list[str] {
    line = line.replace('{', '');
    line = line.replace(')', '');
    line = line.replace('(', '');
    bits = line.split(',');
    return [s.strip() for s in bits[1:]];
}