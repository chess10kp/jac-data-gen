def count_ok(results: list[dict]) -> int {
    return len([r for r in results if r["status"] == "ok"]);
}
