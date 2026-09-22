"""
  formats the supplied bytes
  """
def _get_formatted_size(bytes: int) -> str {
    if bytes < 1000 {
        return ('%i' % bytes) + ' B';
    } elif 1000 <= bytes < 1000000 {
        return ('%.1f' % (bytes / 1000.0)) + ' KB';
    } elif 1000000 <= bytes < 1000000000 {
        return ('%.1f' % (bytes / 1000000.0)) + ' MB';
    } elif 1000000000 <= bytes < 1000000000000 {
        return ('%.1f' % (bytes / 1000000000.0)) + ' GB';
    } else {
        return ('%.1f' % (bytes / 1000000000000.0)) + ' TB';
    }
}