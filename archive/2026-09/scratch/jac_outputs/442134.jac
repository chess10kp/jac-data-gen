"""Return resource units consumed by a gateway service."""
def _parse_gateway(gw_data: dict[str, object]) -> dict[str, float | int] {
    return {"hru": 0, "sru": 0, "mru": 0.1, "cru": 0.1};
}