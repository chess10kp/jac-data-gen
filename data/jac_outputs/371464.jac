"""getin sick."""
def sea_sick(sea: list[str]) -> str {
    sick = 0;
    for i in range(len(sea) - 1) {
        if sea[i] != sea[i + 1] {
            sick += 1;
        }
    }
    if sick > len(sea) * 0.2 {
        return "Throw Up";
    }
    return "No Problem";
}