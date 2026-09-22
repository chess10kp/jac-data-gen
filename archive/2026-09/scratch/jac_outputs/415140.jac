"""Function checks presence of "minlength"="1" in HMI_API if
    "minlength" is omitted in MobileAPI.
    Should be checked only for "type"="String"
    """
def string_compare_rule(
    mob_param_attributes: dict[str, str],
    hmi_param_attributes: dict[str, str]
) -> tuple[dict[str, str | None], dict[str, str | None]] {
    attr = "minlength";
    if attr not in mob_param_attributes {
        if attr not in hmi_param_attributes {
            return ({attr: None}, {attr: None});
        } elif hmi_param_attributes[attr] != "1" {
            return ({attr: None}, {attr: hmi_param_attributes[attr]});
        } else {
            mob_param_attributes[attr] = "1";
        }
    }
    return ({}, {});
}