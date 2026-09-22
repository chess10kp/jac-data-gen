"""
kda = kills + (assists / 2) / deaths
Ensure the MLG's have some deaths.
"""
def calculate_kill_death_assists_ratio(
    kills: int, deaths: int, assists: int
) -> float {
    numerator = kills + assists / 2;
    if deaths > 0 {
        kda = numerator / deaths;
    } else {
        kda = numerator;
    }
    return round(kda, 2);
}