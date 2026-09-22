"""Clean the model field. Best guess."""
def _get_model(vehicle: dict[str, str]) -> str {
    model = vehicle['model'];
    model = model.replace(vehicle['year'], '');
    model = model.replace(vehicle['make'], '');
    return model.strip().split(' ')[0];
}