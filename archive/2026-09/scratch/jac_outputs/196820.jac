glob HOURS_MASK = 0x1F;

"""
  simple mask
  >>> parse_hours(0x0b)
  11

  >>> parse_hours(0x28)
  8

  """
def parse_hours(hours: int) -> int {
    return int(hours & HOURS_MASK);
}