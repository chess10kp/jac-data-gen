def count_ok(results: list[dict]) -> int {
    n = 0;
    for r in results {
        if r.status == "ok" {
            n += 1;
        }
    }
    return n;
}
