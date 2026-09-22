"""Convert degrees Fahrenheit to degrees Celsius."""
def conv_F2C(value: int | float) -> int | float {
    value_c = (value - 32) * (5 / 9);
    if hasattr(value_c, 'units') {
        getattr(value_c, 'attrs').update(units='degC');
    }
    return value_c;
}