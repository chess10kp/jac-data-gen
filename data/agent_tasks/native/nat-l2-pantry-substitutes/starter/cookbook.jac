"""Recipe graph: Recipe -Needs-> Ingredient, Ingredient -SubstitutesFor-> Ingredient."""

node Recipe {
    has title: str;
}

node Ingredient {
    has name: str;
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
