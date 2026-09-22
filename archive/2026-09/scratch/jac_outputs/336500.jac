"""
    Transform an integer confidence value into the DNI scale string
    representation.

    Raises:
        ValueError: If `confidence_value` is out of bounds.
"""
def value_to_dni(confidence_value: int) -> str {
    if 9 >= confidence_value >= 0 {
        return 'Almost No Chance / Remote';
    } elif 19 >= confidence_value >= 10 {
        return 'Very Unlikely / Highly Improbable';
    } elif 39 >= confidence_value >= 20 {
        return 'Unlikely / Improbable';
    } elif 59 >= confidence_value >= 40 {
        return 'Roughly Even Chance / Roughly Even Odds';
    } elif 79 >= confidence_value >= 60 {
        return 'Likely / Probable';
    } elif 89 >= confidence_value >= 80 {
        return 'Very Likely / Highly Probable';
    } elif 100 >= confidence_value >= 90 {
        return 'Almost Certain / Nearly Certain';
    } else {
        raise ValueError(("Range of values out of bounds: %s" % confidence_value));
    }
}