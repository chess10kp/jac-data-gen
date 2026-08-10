"""Return name of directory for results of given settings (only depends on
        model size) and experiment name."""
def make_experiment_dir_name(max_model_size: int, experiment_name: str | None) -> str {
    if experiment_name is not None {
        return f"Experiment={experiment_name}-max_model_size={max_model_size}";
    }
    return f"max_model_size={max_model_size}";
}