"""Re-order list given regular expression listed by priorities."""
def _order_from_regexp(items: list[str], order_regexps: list[str]) -> list[str] {
    import re;
    ordered = [];
    for order_regexp in order_regexps {
        matched = [item for item in items if re.search(order_regexp, item)];
        for item in matched {
            ordered.append(item);
            items.remove(item);
        }
    }
    ordered += items;
    return ordered;
}