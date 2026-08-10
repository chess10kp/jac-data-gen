def data_format_to_shape(
    batch_length: int | None = None,
    sequence_length: int | None = None,
    channel_length: int | None = None,
    data_format: str = 'channels_first'
) -> tuple[int | None, int | None, int | None] {
    shape = [batch_length, None, None];
    channel_axis = 1 if data_format == 'channels_first' else 2;
    sequence_axis = 2 if data_format == 'channels_first' else 1;
    shape[sequence_axis] = sequence_length;
    shape[channel_axis] = channel_length;
    return tuple(shape);
}