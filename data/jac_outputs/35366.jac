"""Return a filename for noiseless parameter sweeps inputs."""
def make_physical_params_sweep_fname(tag: str, param_str: str) -> str {
    return f"physical_parameter_sweep_{tag}_{param_str}.npy";
}