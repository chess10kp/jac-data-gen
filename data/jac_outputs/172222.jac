"""Replace all gll links."""
def replace_gll_link(
    py: str, simulation_directory: str, new_gll_directory: str
) -> str {
    script = f"{py} -m seisflow.scripts.structure_inversion.replace_gll_link --simulation_directory {simulation_directory} --new_gll_directory {new_gll_directory}; \n";
    return script;
}