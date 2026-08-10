"""Convert unit from [len_unit] => [len_unit1]."""
def convert_LengthUnit(len_unit1: str, len_unit: str) -> tuple[str, int | float] {
    if len_unit1 == "" or len_unit1 == len_unit {
        return (len_unit, 1);
    }
    conversions = {
        "ft_km": 0.0003048,
        "kt_km": 1.852,
        "mi_km": 1.609344,
        "m_km": 0.001,
        "km_ft": 3280.8399,
        "km_kt": 0.53996,
        "km_mi": 0.621371,
        "km_m": 1000,
        "km_km": 1
    };
    via_km = conversions[len_unit + "_km"];
    to_target = conversions["km_" + len_unit1];
    return (len_unit1, via_km * to_target);
}