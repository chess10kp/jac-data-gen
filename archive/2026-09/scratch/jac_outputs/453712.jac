"""Return total[], pos1[], pos2[], ... for a horizontal montage."""
def calc_montage_horizontal(border_size: int, *frames: list[int]) -> tuple[list[int], ...] {
    num_frames = len(frames);
    total_width = sum(f[0] for f in frames) + border_size * num_frames + 1;
    max_height = max(f[1] for f in frames);
    total_height = max_height + 2 * border_size;
    x = border_size;
    pos_list = [];
    for f in frames {
        y = border_size + (max_height - f[1]) // 2;
        pos_list.append([x, y]);
        x += f[0] + border_size;
    }
    result = [[total_width, total_height]];
    result.extend(pos_list);
    return tuple(result);
}