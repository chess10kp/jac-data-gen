"""
:param bbox1:
:param bbox2:
:return:
Assumption: One bounding box is contained inside another
"""
def get_bigger_bbox(bbox1: list[tuple[float, float]], bbox2: list[tuple[float, float]]) -> list[tuple[float, float]] {
    min_x_1 = min([p[0] for p in bbox1]);
    min_y_1 = min([p[1] for p in bbox1]);
    max_x_1 = max([p[0] for p in bbox1]);
    max_y_1 = max([p[1] for p in bbox1]);
    min_x_2 = min([p[0] for p in bbox2]);
    min_y_2 = min([p[1] for p in bbox2]);
    max_x_2 = max([p[0] for p in bbox2]);
    max_y_2 = max([p[1] for p in bbox2]);
    if min_x_1 < min_x_2 or min_y_1 < min_y_2 {
        return bbox1;
    }
    if max_x_2 < max_x_1 or max_y_2 < max_y_1 {
        return bbox1;
    }
    return bbox2;
}