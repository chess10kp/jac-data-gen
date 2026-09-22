"""
>>> convert_to_celsius(75)
 23.88888888888889
"""
def convert_to_celsius(fahrenheit: float) -> float {
    return fahrenheit - 32.0 * 5.0 / 9.0;
}