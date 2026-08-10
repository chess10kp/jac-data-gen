"""
    Taken from https://gist.github.com/meyerjo/dd3533edc97c81258898f60d8978eddc
    both boxes should be in format [x1, y1, x2, y2]
    """
def bb_intersection_over_union(
    boxA: Any, boxB: Any, if_return_areas: Any = False
) -> object {
    xA = max(boxA[0], boxB[0]);
    yA = max(boxA[1], boxB[1]);
    xB = min(boxA[2], boxB[2]);
    yB = min(boxA[3], boxB[3]);
    interArea = abs((max(((xB - xA), 0)) * max((yB - yA), 0)));
    boxAArea = abs(((boxA[2] - boxA[0]) * (boxA[3] - boxA[1])));
    boxBArea = abs(((boxB[2] - boxB[0]) * (boxB[3] - boxB[1])));
    iou = interArea / float(((boxAArea + boxBArea) - interArea));
    if not if_return_areas {
        return iou;
    } else {
        return (iou, (interArea, boxAArea, boxBArea));
    }
}