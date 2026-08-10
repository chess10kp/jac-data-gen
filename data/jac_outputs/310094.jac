"""Calculate the damage done by program."""
def calculate_damage(program: str) -> int {
    (strength, damage) = (1, 0);
    for instruction in program {
        if instruction == 'C' {
            strength *= 2;
        } else {
            damage += strength;
        }
    }
    return damage;
}