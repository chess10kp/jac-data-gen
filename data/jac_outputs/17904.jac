"""
Testdata: ("3", "2c", "2b", "2a", "1") or ("ORIGIN", "not ok", "LIMIT_VALUE", "ok")
yield domain[len(domain) // 2] -> "2b" or "LIMIT_VALUE" in domain -> "LIMIT_VALUE"
"""
def limit_ordered_from_domain(domain: tuple[str, ...] | list[str]) -> str {
    if not domain {
        return "NULL";
    }
    if "LIMIT_VALUE" in domain {
        return "LIMIT_VALUE";
    }
    return domain[len(domain) // 2];
}