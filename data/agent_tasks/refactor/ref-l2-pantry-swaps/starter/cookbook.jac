"""Household cookbook: recipes need ingredients, some ingredients can stand in for others."""

node Kitchen {
    has recipes: dict[str, dict[str, bool]] = {};
    has swaps: dict[str, dict[str, bool]] = {};
}

def _kitchen() -> Kitchen {
    for n in [root -->] {
        if isinstance(n, Kitchen) {
            return n;
        }
    }
    k = Kitchen();
    root ++> k;
    return k;
}

def add_recipe(title: str, needs: list[str], optional: list[str]) -> bool {
    k = _kitchen();
    if title in k.recipes {
        return False;
    }
    items: dict[str, bool] = {};
    for n in needs {
        items[n] = False;
    }
    for n in optional {
        items[n] = True;
    }
    k.recipes[title] = items;
    return True;
}

def allow_swap(original: str, replacement: str) -> bool {
    k = _kitchen();
    if original == replacement {
        return False;
    }
    if original not in k.swaps {
        k.swaps[original] = {};
    }
    if replacement in k.swaps[original] {
        return False;
    }
    k.swaps[original][replacement] = True;
    return True;
}

def _options(k: Kitchen, ingredient: str, stock: list[str]) -> list[str] {
    out: list[str] = [];
    if ingredient in k.swaps {
        for r in k.swaps[ingredient] {
            if r in stock {
                out.append(r);
            }
        }
    }
    return sorted(out);
}

def missing(title: str, stock: list[str]) -> list[str] {
    k = _kitchen();
    if title not in k.recipes {
        return [];
    }
    out: list[str] = [];
    items = k.recipes[title];
    for ing in items {
        if items[ing] {
            continue;
        }
        if ing not in stock and len(_options(k, ing, stock)) == 0 {
            out.append(ing);
        }
    }
    return sorted(out);
}

def swaps_needed(title: str, stock: list[str]) -> list[str] {
    k = _kitchen();
    if title not in k.recipes {
        return [];
    }
    out: list[str] = [];
    items = k.recipes[title];
    for ing in items {
        if items[ing] or ing in stock {
            continue;
        }
        opts = _options(k, ing, stock);
        if len(opts) > 0 {
            out.append(ing + "->" + opts[0]);
        }
    }
    return sorted(out);
}

def cookable(stock: list[str]) -> list[str] {
    k = _kitchen();
    out: list[str] = [];
    for title in k.recipes {
        if len(missing(title, stock)) == 0 {
            out.append(title);
        }
    }
    return sorted(out);
}

def used_in(ingredient: str) -> list[str] {
    k = _kitchen();
    out: list[str] = [];
    for title in k.recipes {
        if ingredient in k.recipes[title] {
            out.append(title);
        }
    }
    return sorted(out);
}
