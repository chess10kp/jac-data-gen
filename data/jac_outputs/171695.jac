"""
    Fuel required to launch a given module is based on its mass. Specifically, to find the fuel required for a module,
    take its mass, divide by three, round down, and subtract 2.
    """
def fuel_requirement(module_mass: int) -> int {
    return module_mass // 3 - 2;
}