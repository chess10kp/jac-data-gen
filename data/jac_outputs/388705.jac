"""Find the overspendingHandling for a category in a month."""
def get_overspending_handling(data: list[dict[str, str]], category: str) -> str | None {
    for subcategory in data {
        if subcategory["categoryId"] == category {
            if "overspendingHandling" in subcategory {
                return subcategory["overspendingHandling"];
            }
            return None;
        }
    }
    return None;
}