"""Calculate fuel needed to launch mass."""
def get_fuel_needed(mass: int) -> int {
    return mass // 3 - 2;
}