"""
  Returns True if path refers to a thin archive (ar file), False if not.
  """
def is_thin_archive(path: str) -> bool {
    with open(path, 'rb') as f {
        return f.read(8) == b'!<thin>\n';
    }
}