"""
    Parses reference designator into a dictionary containing subsite, node,
    and sensor.
    """
def ooi_instrument_reference_designator(reference_designator: str) -> dict[str, str] {
    keys = ["subsite", "node", "sensor"];
    val = reference_designator.split("-");
    values = val[:-2] + ["-".join(val[-2:])];
    return dict(zip(keys, values));
}