"""converts wavelength values to standardised representation"""
def wavelength_to_standard(unit: str, values: float) -> float {
    if unit == 'nm' {
        converted_values = values * 1e-09;
    } elif unit == 'um' {
        converted_values = values * 1e-06;
    } elif unit == 'a' {
        converted_values = values * 1e-10;
    } else {
        converted_values = values;
    }
    return converted_values;
}