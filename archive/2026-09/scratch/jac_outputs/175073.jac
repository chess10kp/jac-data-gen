"""Formats an unit to get outputed by the system."""
def _format_unit_output(unit: dict[str, str]) -> str {
    return unit["name"] + " (" + unit["_internal_function_"] + ")";
}