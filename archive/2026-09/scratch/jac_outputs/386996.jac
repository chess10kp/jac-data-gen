"""
    This function takes a pair of bounding boxes and returns intersection-over-
    union (IoU) of two bounding boxes.
    """
def compute_iou(box_1: tuple[int, int, int, int], box_2: tuple[int, int, int, int]) -> float {
    (tl_row_1, tl_col_1, br_row_1, br_col_1) = box_1;
    (tl_row_2, tl_col_2, br_row_2, br_col_2) = box_2;
    assert tl_row_1 < br_row_1;
    assert tl_col_1 < br_col_1;
    assert tl_row_2 < br_row_2;
    assert tl_col_2 < br_col_2;
    area_1 = (br_row_1 - tl_row_1) * (br_col_1 - tl_col_1);
    area_2 = (br_row_2 - tl_row_2) * (br_col_2 - tl_col_2);
    tl_row_i = max(tl_row_1, tl_row_2);
    tl_col_i = max(tl_col_1, tl_col_2);
    br_row_i = min(br_row_1, br_row_2);
    br_col_i = min(br_col_1, br_col_2);
    if br_row_i < tl_row_i or br_col_i < tl_col_i {
        intersection_area = 0;
    } else {
        intersection_area = (br_row_i - tl_row_i) * (br_col_i - tl_col_i);
    }
    union_area = area_1 + area_2 - intersection_area;
    iou = intersection_area / union_area;
    assert iou >= 0 and iou <= 1.0;
    return iou;
}