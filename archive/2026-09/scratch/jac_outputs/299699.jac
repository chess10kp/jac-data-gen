"""Calculates the position of a scanner within its range at a given time step."""
def calc_scanner_pos(scanner_height: int, time_step: int) -> int {
    cycle_midpoint = scanner_height - 1;
    full_cycle = cycle_midpoint * 2;
    cycle_position = time_step % full_cycle;
    return cycle_position if cycle_position <= cycle_midpoint else full_cycle - cycle_position;
}