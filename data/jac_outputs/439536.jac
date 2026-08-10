"""
    Using for further cropping eyes from images with faces
    :param eye:
    :return: x, y, of center of eye
    """
def calc_center(eye: Any) -> object {
    center_x = (eye[0][0] + eye[3][0]) // 2;
    center_y = (eye[0][1] + eye[3][1]) // 2;
    return (int(center_x), int(center_y));
}