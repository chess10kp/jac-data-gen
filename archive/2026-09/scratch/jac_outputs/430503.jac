"""
    Creates a map from stream name to stream size from the indices table.

    :param stream_indices:  The stream indices table.
    :return:                The map.
    """
def create_stream_size_map(stream_indices: Any) -> object {
    return {pair[0]: len(pair[1]) for pair in stream_indices};
}