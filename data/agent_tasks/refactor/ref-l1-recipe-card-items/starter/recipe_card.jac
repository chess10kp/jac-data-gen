"""Recipe cards: a title, a serving count and a list of ingredient lines."""

obj RecipeCard {
    has title: str;
    has servings: int;
    has items: list[dict[str, any]] = [];
}

def add_item(card: RecipeCard, name: str, qty: float, unit: str) -> bool {
    for it in card.items {
        if it["name"] == name {
            return False;
        }
    }
    card.items.append({"name": name, "qty": qty, "unit": unit});
    return True;
}

def rescale(card: RecipeCard, servings: int) -> RecipeCard {
    factor = servings / card.servings;
    out = RecipeCard(title=card.title, servings=servings);
    for it in card.items {
        out.items.append({"name": it["name"], "qty": it["qty"] * factor, "unit": it["unit"]});
    }
    return out;
}

def total_in(card: RecipeCard, unit: str) -> float {
    total = 0.0;
    for it in card.items {
        if it["unit"] == unit {
            total += it["qty"];
        }
    }
    return total;
}

def item_names(card: RecipeCard) -> list[str] {
    names: list[str] = [];
    for it in card.items {
        names.append(it["name"]);
    }
    return names;
}

def swap_item(card: RecipeCard, old: str, new: str) -> bool {
    for it in card.items {
        if it["name"] == old {
            it["name"] = new;
            return True;
        }
    }
    return False;
}
