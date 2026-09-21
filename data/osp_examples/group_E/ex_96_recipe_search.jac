"""Ranked recipe-box search.

Score each hit by where the query lands, then sort best-first with a
lambda key; the weights live in the relevance helper.
"""

node Recipe {
    has name: str;
    has cuisine: str = "";
    has ingredient: str = "";
}

def relevance(r: Recipe, query: str) -> int {
    q = query.lower();
    score = 0;
    if q in r.name.lower() {
        score += 10;  # name hits outrank everything
    }
    if q in r.cuisine.lower() {
        score += 5;
    }
    if q in r.ingredient.lower() {
        score += 2;
    }
    # Shorter names are more on-point for equal hits.
    return score + max(0, 30 - len(r.name));
}

walker:priv add_recipe {
    has name: str;
    has cuisine: str = "";
    has ingredient: str = "";

    can run with Root entry {
        here ++> Recipe(name=self.name, cuisine=self.cuisine, ingredient=self.ingredient);
    }
}

walker:priv search_recipes {
    has query: str;
    has matches: list[dict] = [];

    can start with Root entry {
        visit [-->];
    }

    can check with Recipe entry {
        if self.query.lower() in (here.name + here.cuisine + here.ingredient).lower() {
            self.matches.append({
                "id": jid(here),
                "name": here.name,
                "score": relevance(here, self.query),
            });
        }
    }

    can finish with Root exit {
        self.matches.sort(key=lambda (x: any) { x["score"]; }, reverse=True);
        report {"query": self.query, "hits": self.matches};
    }
}

with entry {
    root spawn add_recipe(name="Massaman Curry", cuisine="thai", ingredient="potato");
    root spawn add_recipe(name="Basic Curry Sauce", cuisine="fusion", ingredient="onion");
    root spawn add_recipe(name="Slow Simmered Dahl", cuisine="indian", ingredient="curry powder");
    root spawn add_recipe(name="Cauliflower Steaks", cuisine="italian", ingredient="red curry paste");

    result = root spawn search_recipes(query="curry");
    print(result.reports);
}
