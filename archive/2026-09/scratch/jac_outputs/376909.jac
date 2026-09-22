"""At least one quantity band must have positive value."""
def get_trader_fcas_availability_max_quantity_condition(params: dict[str, dict[str, int]]) -> bool {
    max_quantity = max(params['quantity_bands'].values());
    return max_quantity > 0;
}