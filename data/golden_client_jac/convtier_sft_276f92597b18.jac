def average_temperature(temps: list[int]) -> int {
    if len(temps) == 0 { raise ValueError("No temperatures provided."); }
    total = sum(temps);
    return round(total / len(temps));
}

with entry {
    print(average_temperature([10, 20, 30]));
}
