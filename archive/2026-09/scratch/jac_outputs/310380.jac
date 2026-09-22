def lose(power_pellet_active: bool, touching_ghost: bool) -> bool {
    return not power_pellet_active and touching_ghost;
}