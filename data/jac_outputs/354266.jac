"""Heaviside function Theta(x)"""
def Heaviside(x: Any) -> object {
    if (x < 0) {
        return 0;
    } elif (x > 0) {
        return 1;
    }
    return 0.5;
}