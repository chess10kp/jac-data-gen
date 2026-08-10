"""Convert a 'Content-Range' header into a length for the response."""
def _process_content_range(content_range: str) -> int {
    (_, _, range_spec) = content_range.partition(' ');
    (byte_range, _, _) = range_spec.partition('/');
    (start, _, end) = byte_range.partition('-');
    return int(end) - int(start) + 1;
}