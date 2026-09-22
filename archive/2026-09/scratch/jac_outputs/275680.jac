"""Converts metadata from CVAT format."""
def get_metadata(data: dict[str, str | dict[str, int | dict[str, int]]]) -> dict[str, int | str] {
    metadata = {};
    metadata['source_name'] = data['source'];
    metadata['frames_size'] = data['task']['size'];
    metadata['start_frame'] = data['task']['start_frame'];
    metadata['stop_frame'] = data['task']['stop_frame'];
    metadata['video_width'] = data['task']['original_size']['width'];
    metadata['video_height'] = data['task']['original_size']['height'];
    return metadata;
}