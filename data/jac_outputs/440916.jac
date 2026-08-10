"""Helper callback to set default edge styles."""
def _EdgeStyle(data: dict[str, str]) -> str {
    `flow = data.get("flow");
    return "dashed" if `flow in ("backward_control", "backward_data", "backward_call") else "solid";
}