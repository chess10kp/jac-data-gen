"""
    Method to find the bottom center of every bbox

    Input:
        bboxes: all the boxes containing "person"

    Returns:
        Return a list of bottom center of every bbox
    """
def mid_point(bboxes: list[list[int]]) -> list[tuple[int, int]] {
    mid_values = list();
    for coor in bboxes {
        x1 = coor[0];
        y1 = coor[1];
        x2 = coor[2];
        y2 = coor[3];
        x_mid = int(x1 - ((x1 - (x1 + x2)) / 2));
        y_mid = int(y1 + y2);
        mid_values.append((x_mid, y_mid));
    }
    return mid_values;
}