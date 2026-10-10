"""Household cookbook: recipes need ingredients, some ingredients can stand in for others."""

node Recipe {
    has title: str;
}

node Ingredient {
    has name: str;
}

edge Needs: Recipe --> Ingredient {
    has optional: bool = False;
}

edge SwapsTo: Ingredient --> Ingredient {}

def find_recipe(title: str) -> Recipe | None {
    wanted = title;
    found = [root -->[?:Recipe, title == wanted]];
    return found[0] if found else None;
}

def find_ingredient(label: str) -> Ingredient | None {
    found = [root -->[?:Ingredient, name == label]];
    return found[0] if found else None;
}

def ingredient(label: str) -> Ingredient {
    ing = find_ingredient(label);
    if ing is None {
        ing = Ingredient(name=label);
        root ++> ing;
    }
    return ing;
}

def add_recipe(title: str, needs: list[str], optional: list[str]) -> bool {
    if find_recipe(title) is not None {
        return False;
    }
    r = Recipe(title=title);
    root ++> r;
    for n in needs {
        r +>:Needs(optional=False):+> ingredient(n);
    }
    for n in optional {
        r +>:Needs(optional=True):+> ingredient(n);
    }
    return True;
}

def allow_swap(original: str, replacement: str) -> bool {
    if original == replacement {
        return False;
    }
    o = ingredient(original);
    if replacement in [s.name for s in [o ->:SwapsTo:->]] {
        return False;
    }
    o +>:SwapsTo():+> ingredient(replacement);
    return True;
}

def options(ing: Ingredient, stock: list[str]) -> list[str] {
    return sorted([s.name for s in [ing ->:SwapsTo:->] if s.name in stock]);
}

def missing(title: str, stock: list[str]) -> list[str] {
    r = find_recipe(title);
    if r is None {
        return [];
    }
    return sorted([
        i.name for i in [r ->:Needs:optional == False:->]
        if i.name not in stock and len(options(i, stock)) == 0
    ]);
}

def swaps_needed(title: str, stock: list[str]) -> list[str] {
    r = find_recipe(title);
    if r is None {
        return [];
    }
    out: list[str] = [];
    for i in [r ->:Needs:optional == False:->] {
        opts = options(i, stock);
        if i.name not in stock and len(opts) > 0 {
            out.append(i.name + "->" + opts[0]);
        }
    }
    return sorted(out);
}

def cookable(stock: list[str]) -> list[str] {
    return sorted([r.title for r in [root -->[?:Recipe]] if len(missing(r.title, stock)) == 0]);
}

def used_in(ingredient: str) -> list[str] {
    ing = find_ingredient(ingredient);
    if ing is None {
        return [];
    }
    return sorted([r.title for r in [ing <-:Needs:<-]]);
}
