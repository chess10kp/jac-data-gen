"""Compute intersection-over-union for two rectangles (y0, x0, y1, x1)."""
def compute_iou(rec1: tuple[int, int, int, int], rec2: tuple[int, int, int, int]) -> float {
    s_rec1 = (rec1[2] - rec1[0]) * (rec1[3] - rec1[1]);
    s_rec2 = (rec2[2] - rec2[0]) * (rec2[3] - rec2[1]);
    sum_area = s_rec1 + s_rec2;
    left_line = max(rec1[1], rec2[1]);
    right_line = min(rec1[3], rec2[3]);
    top_line = max(rec1[0], rec2[0]);
    bottom_line = min(rec1[2], rec2[2]);
    if left_line >= right_line or top_line >= bottom_line {
        return 0;
    }
    intersect = (right_line - left_line) * (bottom_line - top_line);
    return intersect / (sum_area - intersect);
}