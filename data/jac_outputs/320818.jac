"""
    Returns the formatted units for a given asset and amount.
    """
def balance_formatter(asset_info: Any) -> object {
    decimals = asset_info.get("decimals");
    unit = asset_info.get("unitname");
    total = asset_info.get("total");
    formatted_amount = total / (10 ** decimals);
    return "{} {}".format(formatted_amount, unit);
}