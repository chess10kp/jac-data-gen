"""Inverts age_to_eye_diameter

    Args:
         D_eye (float): Diameter of Eyepiece (mm); default is 7 mm
    Returns:
         age (float): approximate age
    """
def eye_to_age(D_eye: float) -> int {
    if D_eye > 7.25 {
        return 15;
    } elif D_eye <= 7.25 and D_eye > 6.75 {
        return 25;
    } elif D_eye <= 6.75 and D_eye > 6.25 {
        return 33;
    } elif D_eye <= 6.25 and D_eye > 5.75 {
        return 40;
    } elif D_eye <= 5.75 and D_eye > 5.25 {
        return 54;
    } else {
        return 70;
    }
}