"""
    Computes quaternion multiplication
    :param q: Quaternion
    :param r: Quaternion
    :return:
    """
def quaternion_multiply(q: Any, r: Any) -> object {
    q_w = q[0];
    q_x = q[1];
    q_y = q[2];
    q_z = q[3];
    r_w = r[0];
    r_x = r[1];
    r_y = r[2];
    r_z = r[3];
    return [
        ((q_w * r_w) - (q_x * r_x) - (q_y * r_y) - (q_z * r_z)),
        (((q_w * r_x) + (q_x * r_w) + (q_y * r_z)) - (q_z * r_y)),
        (((q_w * r_y) + (q_y * r_w) + (q_z * r_x)) - (q_x * r_z)),
        (((q_w * r_z) + (q_z * r_w) + (q_x * r_y)) - (q_y * r_x))
    ];
}