"""Calculate shifts from z = 0 for each phase."""
def calc_z_shifts(zphase: float, zsubstrate: float, margin: float) -> dict[str, float] {
    shifts: dict[str, float] = {};
    shifts['sub_bottom'] = margin;
    sub_bottom_upper_margin = shifts['sub_bottom'] + zsubstrate;
    shifts['phase'] = sub_bottom_upper_margin + margin;
    phase_upper_margin = shifts['phase'] + zphase;
    shifts['sub_top'] = phase_upper_margin + margin;
    sub_top_upper_margin = shifts['sub_top'] + zsubstrate;
    shifts['box_z'] = sub_top_upper_margin + margin;
    return shifts;
}