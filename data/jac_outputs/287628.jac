"""Determine if charge level is supported."""
def _ev_charge_level_supported(
    data: dict[str, bool | dict[str, dict[str, dict[str, int | float | None]]]]
) -> bool {
    if not data["isElectric"] {
        return False;
    }
    return data["evStatus"]["chargeInfo"]["batteryLevelPercentage"] is not None;
}