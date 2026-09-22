"""convert a str to valid latitude"""
def str2latitute(value: str) -> float {
    if "." not in value {
        value = value[:2] + "." + value[2:];
    }
    return float(value);
}