"""Return settle times for gates on a station"""
def waitTime(
    gate: int | None,
    station: object | None = None,
    gate_settle: Callable[[int], float] | None = None,
    `default: float = 0.001
) -> float {
    if gate is None {
        return 0.001;
    }
    if gate_settle is not None {
        return gate_settle(gate);
    }
    if station is not None {
        if hasattr(station, 'gate_settle') {
            return (getattr(station, 'gate_settle') as Callable[[int], float])(gate);
        }
    }
    return `default;
}