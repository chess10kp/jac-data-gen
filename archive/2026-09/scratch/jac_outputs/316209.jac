"""We assume that the N has the highest knowledge of N."""
def get_highest_knowledge(knowledge: dict[str, dict[str, int | float | str | bool]]) -> dict[str, int | float | str | bool] {
    k: dict[str, int | float | str | bool] = {};
    for key in knowledge {
        k[key] = knowledge[key][key];
    }
    return k;
}