"""Remove diag-specific models from project_models."""
def remove_diag_specific_models(project_models: list) -> list {
    return [model for model in project_models if not model.is_diag_specific()];
}