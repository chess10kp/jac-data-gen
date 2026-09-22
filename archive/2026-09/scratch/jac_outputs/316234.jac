"""For chunks of fps number of frames for actual as well as predicted viewports."""
def get_chunks(
    act_viewport: list[object],
    pred_viewport: list[object],
    frame_nos: list[object],
    max_frame: int,
    fps: int
) -> tuple[list[list[object]], list[list[object]], list[list[object]]] {
    act_tiles: list[list[object]] = [];
    pred_tiles: list[list[object]] = [];
    chunk_frames: list[list[object]] = [];
    chunk_size = fps;
    number_of_chunks = int(len(act_viewport) / chunk_size);
    for i in range(number_of_chunks) {
        start = i * chunk_size;
        end = (i + 1) * chunk_size;
        act_tiles.append(act_viewport[start:end]);
        pred_tiles.append(pred_viewport[start:end]);
        chunk_frames.append(frame_nos[start:end]);
    }
    remainder_start = number_of_chunks * chunk_size;
    act_tiles.append(act_viewport[remainder_start:]);
    pred_tiles.append(pred_viewport[remainder_start:]);
    chunk_frames.append(frame_nos[remainder_start:]);
    return (act_tiles, pred_tiles, chunk_frames);
}