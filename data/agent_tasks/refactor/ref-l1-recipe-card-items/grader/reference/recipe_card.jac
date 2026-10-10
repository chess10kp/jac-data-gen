"""Recipe cards: a title, a serving count and a list of ingredient lines."""

obj Item {
    has name: str;
    has qty: float;
    has unit: str;
}

obj RecipeCard {
    has title: str;
    has servings: int;
    has items: list[Item] = [];

    def find(name: str) -> Item | None {
        for it in self.items {
            if it.name == name {
                return it;
            }
        }
        return None;
    }
}

def add_item(card: RecipeCard, name: str, qty: float, unit: str) -> bool {
    if card.find(name) is not None {
        return False;
    }
    card.items.append(Item(name=name, qty=qty, unit=unit));
    return True;
}

def rescale(card: RecipeCard, servings: int) -> RecipeCard {
    factor = servings / card.servings;
    return RecipeCard(
        title=card.title,
        servings=servings,
        items=[Item(name=it.name, qty=it.qty * factor, unit=it.unit) for it in card.items]
    );
}

def total_in(card: RecipeCard, unit: str) -> float {
    return sum([it.qty for it in card.items if it.unit == unit], 0.0);
}

def item_names(card: RecipeCard) -> list[str] {
    return [it.name for it in card.items];
}

def swap_item(card: RecipeCard, old: str, new: str) -> bool {
    it = card.find(old);
    if it is None {
        return False;
    }
    it.name = new;
    return True;
}
