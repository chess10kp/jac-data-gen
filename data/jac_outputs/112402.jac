"""
    Computer Intersection Over Union
    """
def get_iou(box1: list[int], box2: list[int]) -> float {
    xA = max(box1[0], box2[0]);
    yA = max(box1[1], box2[1]);
    xB = min(box1[2], box2[2]);
    yB = min(box1[3], box2[3]);
    inter_area = max(0, xB - xA + 1) * max(0, yB - yA + 1);
    box1_area = (box1[2] - box1[0] + 1) * (box1[3] - box1[1] + 1);
    box2_area = (box2[2] - box2[0] + 1) * (box2[3] - box2[1] + 1);
    union_area = box1_area + box2_area - inter_area;
    return inter_area / float(union_area);
}