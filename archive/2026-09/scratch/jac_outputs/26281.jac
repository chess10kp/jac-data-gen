"""Calculate the Intersection over Union (IoU) of two bounding boxes."""
def get_iou(bb1: dict[str, float], bb2: dict[str, float]) -> float {
    assert bb1['x1'] <= bb1['x2'];
    assert bb1['y1'] <= bb1['y2'];
    assert bb2['x1'] <= bb2['x2'];
    assert bb2['y1'] <= bb2['y2'];
    x_left = max(bb1['x1'], bb2['x1']);
    y_top = max(bb1['y1'], bb2['y1']);
    x_right = min(bb1['x2'], bb2['x2']);
    y_bottom = min(bb1['y2'], bb2['y2']);
    if x_right < x_left or y_bottom < y_top {
        return 0.0;
    }
    intersection_area = (x_right - x_left) * (y_bottom - y_top);
    bb1_area = (bb1['x2'] - bb1['x1']) * (bb1['y2'] - bb1['y1']);
    bb2_area = (bb2['x2'] - bb2['x1']) * (bb2['y2'] - bb2['y1']);
    iou = intersection_area / float(bb1_area + bb2_area - intersection_area);
    assert iou >= 0.0;
    assert iou <= 1.0;
    return iou;
}