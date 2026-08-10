"""parse_int

  :param m:
  :param default:
  """
def parse_int(m: Any, `default: Any = 0) -> object {
    if (`type(m) == int) {
        return m;
    } elif (`type(m) == str) {
        try {
            return int(m);
        } except Exception as e {
            return `default;
        }
    } else {
        raise Exception(('error input %s, cannot parse' % m));
    }
}