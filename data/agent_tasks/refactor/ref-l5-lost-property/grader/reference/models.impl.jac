impl category_named(name: str) -> Category | None {
    for c in Category {
        if c.value == name {
            return c;
        }
    }
    return None;
}

impl Station.next_tag -> str {
    self.issued += 1;
    return f"{self.name}-{self.issued}";
}

impl Item.is_claimed -> bool {
    return len([self ->:ClaimedBy:->]) > 0;
}

impl Item.matches(category: Category, color: str, since_day: int) -> bool {
    return self.category == category and self.color.lower() == color.lower() and self.day >= since_day;
}
