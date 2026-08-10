"""Calculate okta based on the provided percentage."""
def calculate_okta(percentage: float) -> int {
    if percentage == 0 {
        return 0;
    } elif 0 < percentage < 18.75 {
        return 1;
    } elif 18.75 <= percentage < 31.25 {
        return 2;
    } elif 31.25 <= percentage < 43.75 {
        return 3;
    } elif 43.75 <= percentage < 56.25 {
        return 4;
    } elif 56.25 <= percentage < 68.75 {
        return 5;
    } elif 68.75 <= percentage < 81.25 {
        return 6;
    } elif 81.25 <= percentage < 100 {
        return 7;
    } elif percentage == 100 {
        return 8;
    } else {
        raise ValueError('percentage is not between 0-100');
    }
}