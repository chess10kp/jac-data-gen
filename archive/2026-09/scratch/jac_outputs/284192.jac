"""
  Returns a segment of a string, starting at start_num. The first character in text has
  start_num 1.
  """
def MID(text: str, start_num: int, num_chars: int) -> str {
    if start_num < 1 {
        raise ValueError("start_num invalid");
    }
    return text[(start_num - 1):(start_num - 1 + num_chars)];
}