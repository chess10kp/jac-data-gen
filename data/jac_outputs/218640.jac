"""Calculate minimum D20 roll needed to hit the target player."""
def get_hit_limit_value(
    armour_value: float, mobility_value: float, attack_speed: float
) -> int | None {
    print("Attacking Speed: " + str(attack_speed));
    print("Enemy Armour: " + str(armour_value) + " Mobility: " + str(mobility_value));
    if attack_speed > mobility_value {
        return round(
            (
                (armour_value * 6) - ((armour_value * 3) / (attack_speed / mobility_value))
            ) / 5
        );
    } elif attack_speed < mobility_value {
        return round(
            (
                (armour_value * 6) - (armour_value * 3 * (attack_speed / mobility_value))
            ) / 5
        );
    }
}