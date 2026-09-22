"""Return a filename for noiseless parameter sweeps inputs."""
def make_noisy_params_sweep_fname(tag: str, param_str: str) -> str {
    f"noisy_parameter_sweep_{tag}_{param_str}.npy"
}