"""Function that returns UR script for setting digital out"""
def set_digital_out(id: int, signal: bool) -> str {
    return "set_digital_out({:d}, {})\n".format(id, signal);
}