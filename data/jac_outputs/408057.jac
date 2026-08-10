"""Intersection over union between two bounding boxes."""
def bb_intersection_over_union(boxA: list[int], boxB: list[int]) -> float {
    xA = max(boxA[0], boxB[0]);
    yA = max(boxA[1], boxB[1]);
    xB = min(boxA[2], boxB[2]);
    yB = min(boxA[3], boxB[3]);
    if xA > xB or yA > yB {
        return 0;
    }
    inter_area = (xB - xA + 1) * (yB - yA + 1);
    box_a_area = (boxA[2] - boxA[0] + 1) * (boxA[3] - boxA[1] + 1);
    box_b_area = (boxB[2] - boxB[0] + 1) * (boxB[3] - boxB[1] + 1);
    return inter_area / float(box_a_area + box_b_area - inter_area);
}