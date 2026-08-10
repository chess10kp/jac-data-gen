"""Convert network's sigmoid output into depth prediction"""
def disp_to_depth(disp: float, min_depth: float, max_depth: float) -> tuple[float, float] {
    min_disp = 1 / max_depth;
    max_disp = 1 / min_depth;
    scaled_disp = min_disp + (max_disp - min_disp) * disp;
    depth = 1 / scaled_disp;
    return (scaled_disp, depth);
}