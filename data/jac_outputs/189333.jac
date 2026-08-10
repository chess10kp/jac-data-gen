"""Compute the weighted percentage. The gravity is near 0%."""
def weight_pp(perc: float) -> float {
    if perc > 75.0 {
        return perc;
    } elif perc > 50.0 {
        return perc * 0.75;
    } else {
        return perc * 0.5;
    }
}