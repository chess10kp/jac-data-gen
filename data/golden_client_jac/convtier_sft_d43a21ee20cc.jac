def leaderboard(rows: list[dict]) -> list[str] {
    ranked: list[dict] = sorted(rows, key=lambda r: dict : -r["score"]);
    return [f"{i}. {r['name']} ({r['score']})" for (i, r) in enumerate(ranked, 1)];
}

with entry {
    print(leaderboard([{'name': 'ana', 'score': 12}, {'name': 'bo', 'score': 30}]));
}
