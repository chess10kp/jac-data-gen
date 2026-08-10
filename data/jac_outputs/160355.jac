"""
returns quanity of living squares
"""
def life_counter(field: list[list[str]]) -> int {
    hype = 0;
    for row in field {
        for cell in row {
            if cell == 'o' {
                hype += 1;
            }
        }
    }
    return hype;
}