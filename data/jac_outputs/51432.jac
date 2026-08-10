"""Decide whether to turn on or off the sweep when single or sweep mode is selected."""
def sweep_activation_toggle(
    _: bool,
    sourced_val: float,
    meas_triggered: bool,
    swp_on: bool,
    swp_stop: float,
    swp_step: float,
    mode_choice: bool
) -> bool {
    if mode_choice is False {
        return False;
    }
    if swp_on {
        return float(sourced_val) <= float(swp_stop) - float(swp_step);
    }
    if not meas_triggered {
        return False;
    }
    return True;
}