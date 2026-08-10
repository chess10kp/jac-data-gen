"""
    Format is:
    13:48:06.1133090 - RX - 172 254 137 4 212 128 194 137
  """
def canon_nexiq(msg: str) -> list[int] {
    return [int(x) for x in msg.strip().split(" ")[4:]];
}