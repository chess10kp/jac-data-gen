"""Aggregate web/asset summary into missing, complete, or partial status."""
def get_status(summary: dict[str, dict[str, int | str]]) -> str {
    _summary = {
        k: v
        for (k, v) in summary.items()
        if k in ("web html", "web pdf", "renditions", "assets")
    };
    total = sum(item.get("total", 0) for item in _summary.values());
    total_u = sum(item.get("total unavailable", 0) for item in _summary.values());
    total_i = _summary.get("web html", {}).get("total incomplete", 0);
    if total == 0 or total == total_u {
        return "missing";
    }
    if total_u == total_i == 0 and total > 0 {
        return "complete";
    }
    return "partial";
}