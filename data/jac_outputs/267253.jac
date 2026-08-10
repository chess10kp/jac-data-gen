"""Testdata: ("3", "2c", "2b", "2a", "1") or ("ORIGIN", "not ok", "LIMIT_VALUE", "ok")
yield domain[-1] -> "1" or domain[-1] -> "ok"."""
def max_ordered_from_domain(domain: list[str] | tuple[str, ...]) -> str {
    domain[-1] if domain else "NULL"
}