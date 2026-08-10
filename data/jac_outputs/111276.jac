"""Calculating boxboundary offsets for each segment"""
def bounding_box_to_offsets(bbox: list[float], transform: list[float]) -> list[int] {
    col1 = int((bbox[0] - transform[0]) / transform[1]);
    col2 = int((bbox[1] - transform[0]) / transform[1]) + 1;
    row1 = int((bbox[3] - transform[3]) / transform[5]);
    row2 = int((bbox[2] - transform[3]) / transform[5]) + 1;
    return [row1, row2, col1, col2];
}