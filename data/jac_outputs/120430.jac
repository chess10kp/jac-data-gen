"""Return pixel scale for an instrument type (VRO, Euclid, HST, HST_Up, AO)."""
def pixel_scale_from_instrument(instrument: str) -> tuple[float, float] {
    if instrument in "vro" {
        return (0.2, 0.2);
    } elif instrument in "euclid" {
        return (0.1, 0.1);
    } elif instrument in "hst" {
        return (0.05, 0.05);
    } elif instrument in "hst_up" {
        return (0.03, 0.03);
    } elif instrument in "ao" {
        return (0.01, 0.01);
    } else {
        raise ValueError("An invalid instrument was entered - ", instrument);
    }
}