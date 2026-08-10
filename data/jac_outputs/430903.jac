"""Builds history object."""
def build_history_object(metrics: list[str]) -> dict[str, dict[str, list[float]]] {
    history: dict[str, dict[str, list[float]]] = {
        'batchwise': {},
        'epochwise': {}
    };
    for matrix in metrics {
        history["batchwise"][f"training_{matrix}"] = [];
        history["batchwise"][f"validation_{matrix}"] = [];
        history["epochwise"][f"training_{matrix}"] = [];
        history["epochwise"][f"validation_{matrix}"] = [];
    }
    return history;
}