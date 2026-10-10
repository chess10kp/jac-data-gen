"""Recipe graph: Recipe -Needs-> Ingredient, Ingredient -SubstitutesFor-> Ingredient."""

node Recipe {
    has title: str;
}

node Ingredient {
    has name: str;

    """Name to cook with given the pantry: itself, else best direct substitute, else None."""
    def usable(pantry: list[str]) -> str | None {
        if self.name in pantry {
            return self.name;
        }
        best: str | None = None;
        for sub in [self ->:SubstitutesFor:->] {
            if sub.name in pantry and (best is None or sub.name < best) {
                best = sub.name;
            }
        }
        return best;
    }
}

edge Needs: Recipe --> Ingredient {
    has optional: bool = False;
}

edge SubstitutesFor: Ingredient --> Ingredient {}

obj CookPlan {
    has title: str;
    has swaps: list[str] = [];
}

"""Get-or-create the ingredient node (ingredients hang off root so they are shared)."""
def ingredient(label: str) -> Ingredient {
    found = [root -->[?:Ingredient, name == label]];
    if found {
        return found[0];
    }
    return root ++> Ingredient(name=label);
}

def add_recipe(title: str, needs: list[str], optional: list[str]) -> Recipe {
    r = root ++> Recipe(title=title);
    for n in needs {
        r +>:Needs(optional=False):+> ingredient(n);
    }
    for n in optional {
        r +>:Needs(optional=True):+> ingredient(n);
    }
    return r;
}

def allow_substitute(original: str, replacement: str) {
    ingredient(original) +>:SubstitutesFor():+> ingredient(replacement);
}

walker WhatCanICook {
    has pantry: list[str];
    has found: dict[str, list[str]] = {};

    can start with Root entry {
        visit [-->[?:Recipe]];
    }

    can consider with Recipe entry {
        swaps: list[str] = [];
        ok = True;
        for ing in [here ->:Needs:optional == False:->] {
            use = ing.usable(self.pantry);
            if use is None {
                ok = False;
                break;
            }
            if use != ing.name {
                swaps.append(ing.name + "->" + use);
            }
        }
        if ok {
            swaps.sort();
            self.found[here.title] = swaps;
        }
    }

    can finish with Root exit {
        report [CookPlan(title=t, swaps=self.found[t]) for t in sorted(self.found.keys())];
    }
}
