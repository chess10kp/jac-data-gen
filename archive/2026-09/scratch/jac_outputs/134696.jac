"""Determine applicable experience boost percentage from ability scores."""
def experience_boost_determination(ability_scores: list[tuple[str, int]], prime_ability: str) -> str {
    abilities = [
        'Strength',
        'Intelligence',
        'Wisdom',
        'Dexterity',
        'Constitution',
        'Charisma'
    ];
    prime = abilities.index(prime_ability);
    stat = ability_scores[prime][1];
    if stat in (13, 14) {
        return '5%';
    } elif stat >= 15 {
        return '10%';
    }
    return '0%';
}