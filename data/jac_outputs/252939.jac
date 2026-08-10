"""Add prefix for dict keys with the given prefix string."""
def add_prefix(inputs: dict[str, str], prefix: str) -> dict[str, str] {
    outputs = dict();
    for (name, value) in inputs.items() {
        outputs[f"{prefix}.{name}"] = value;
    }
    return outputs;
}