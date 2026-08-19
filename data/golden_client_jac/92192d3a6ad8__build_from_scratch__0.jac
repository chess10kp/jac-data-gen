def _summary_code(results: list) -> int {
    for r in results {
        if r["status"] == "ok" { return 0; }
    }
    return 1;
}
