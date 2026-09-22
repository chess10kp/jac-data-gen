"""Multiply the inverse of a rotation matrix by a vector."""
def apply_inverse_rot_to_vec(rot: Any, vec: Any) -> object {
    return [
        ((rot[0][0] * vec[0]) + (rot[1][0] * vec[1]) + (rot[2][0] * vec[2])),
        ((rot[0][1] * vec[0]) + (rot[1][1] * vec[1]) + (rot[2][1] * vec[2])),
        ((rot[0][2] * vec[0]) + (rot[1][2] * vec[1]) + (rot[2][2] * vec[2]))
    ];
}