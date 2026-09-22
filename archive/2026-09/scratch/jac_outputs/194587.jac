"""
This gross parser takes the bytes from the soxi output, decodes to utf-8,
splits by the newline "\\n", takes the second element of the array which is
the number of channels, splits by the semi-colon ':' takes the second element
which is the string of the num channels and converts to int.
"""
def parse_soxi_out(cmd: bytes) -> int {
    int(cmd.decode("utf-8").strip().split("\n")[1].split(':')[1].strip())
}