"""Convert dict of parameters to the CLI format."""
def _format_training_params(params: dict[str, bool | str | int | float]) -> str {
    outputs = [];
    for (k, v) in params.items() {
        if isinstance(v, bool) {
            if v {
                outputs.append(f"--{k}");
            }
        } else {
            outputs.append(f"--{k} {v}");
        }
    }
    return " ".join(outputs);
}