"""Intersection over union (IoU) between two axis-aligned boxes."""
def iou(box1: list[int], box2: list[int]) -> float {
    (box1_x1, box1_y1, box1_x2, box1_y2) = box1;
    (box2_x1, box2_y1, box2_x2, box2_y2) = box2;
    xi1 = max(box1_x1, box2_x1);
    yi1 = max(box1_y1, box2_y1);
    xi2 = min(box1_x2, box2_x2);
    yi2 = min(box1_y2, box2_y2);
    inter_width = xi2 - xi1;
    inter_height = yi2 - yi1;
    inter_area = max(inter_width, 0) * max(inter_height, 0);
    box1_area = abs((box1_x2 - box1_x1) * (box1_y2 - box1_y1)) as float;
    box2_area = abs((box2_x2 - box2_x1) * (box2_y2 - box2_y1)) as float;
    union_area = box1_area + box2_area - inter_area;
    return inter_area / union_area;
}