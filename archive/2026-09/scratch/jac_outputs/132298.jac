"""
    Parse whether or not the ad indicates "military friendly".
      parts -> The backpage ad's posting_body, separated into substrings
  """
def parse_military_friendly(parts: list[str]) -> int {
    for part in parts {
        if 'military' in part {
            return 1;
        }
    }
    return 0;
}