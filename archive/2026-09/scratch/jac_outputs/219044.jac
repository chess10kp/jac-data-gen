"""Returns the metadata for the media stream in an MXF file, discarding data streams."""
def get_media_stream(streams: list[dict[str, str]]) -> dict[str, str] | None {
    found = None;
    for stream in streams {
        if stream['codec_type'] in ('data', 'audio') {
            continue;
        }
        if found {
            raise UserWarning('Expected only one media stream per MXF.');
        }
        found = stream;
    }
    return found;
}