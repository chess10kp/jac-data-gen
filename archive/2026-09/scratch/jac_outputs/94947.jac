"""
    Format is:
    139,99,22
    Handler for messages that income as decimal, as opposed to hex
  """
def canon_decimal(msg: str) -> list[int] {
    return [int(x) for x in msg.strip().split(",")];
}