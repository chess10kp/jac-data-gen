"""Discount admin cost based on return period."""
def discount_admin_cost(cost: float, timestep: int, global_parameters: dict[str, float]) -> float {
    discount_rate = global_parameters['discount_rate'] / 100;
    discounted_cost = cost / ((1 + discount_rate) ** timestep);
    return discounted_cost;
}