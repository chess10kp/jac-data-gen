"""Converts windspeed in m/s into Beaufort Scale descriptor."""
def beaufort(n: float) -> str {
    if n < 0.3 {
        return 'calm';
    } elif n < 1.6 {
        return 'light air';
    } elif n < 3.4 {
        return 'light breeze';
    } elif n < 5.5 {
        return 'gentle breeze';
    } elif n < 8.0 {
        return 'moderate breeze';
    } elif n < 10.8 {
        return 'fresh breeze';
    } elif n < 13.9 {
        return 'strong breeze';
    } elif n < 17.2 {
        return 'high wind';
    } elif n < 20.8 {
        return 'gale';
    } elif n < 24.5 {
        return 'strong gale';
    } elif n < 28.5 {
        return 'storm';
    } elif n < 32.7 {
        return 'violent storm';
    }
    return 'hurricane force';
}