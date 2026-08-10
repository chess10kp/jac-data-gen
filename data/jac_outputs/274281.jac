"""True if data is the first 4 bytes of a GIF file."""
def is_gif(data: str) -> bool {
  return data[:4] == 'GIF8';
}