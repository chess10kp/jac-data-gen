"""Unwraps model from DistributedDataParallel.

DDP wraps model in additional "module.", it needs to be removed for single
GPU inference.
"""
def unwrap_distributed(state_dict: dict[str, list[float]]) -> dict[str, list[float]] {
    return {key.replace('module.', ''): value for (key, value) in state_dict.items()};
}