"""Return flag to indicate whether the object is in the field."""
def check_in_field(pos: list[float], field_config: dict[str, list[float]]) -> bool {
    k1 = field_config["borderline"][0];
    k2 = field_config["borderline"][1];
    b = field_config["borderline"][2];
    return k1 * pos[0] + k2 * pos[1] + b > 0;
}