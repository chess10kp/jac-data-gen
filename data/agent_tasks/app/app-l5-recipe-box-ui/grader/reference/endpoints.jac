"""Recipe box server: Recipe nodes share Ingredient nodes via Uses edges."""

node Recipe {
    has title: str;
    has minutes: int = 0;
    has stars_total: int = 0;
    has stars_count: int = 0;
}

node Ingredient {
    has name: str;
}

edge Uses: Recipe --> Ingredient {}

def recipe_view(r: Recipe) -> dict[str, any] {
    avg = round(r.stars_total / r.stars_count, 1) if r.stars_count else 0.0;
    return {"id": jid(r), "title": r.title, "minutes": r.minutes,
            "ingredients": sorted([i.name for i in [r ->:Uses:->]]),
            "rating": avg, "ratings": r.stars_count};
}

def by_title(views: list[dict[str, any]]) -> list[dict[str, any]] {
    return sorted(views, key=lambda (v: dict[str, any]) -> str { return v["title"]; });
}

walker:pub add_recipe {
    has title: str;
    has ingredients: list[str] = [];
    has minutes: int = 0;

    can add with Root entry {
        if not self.title.strip() {
            report {"error": "title required"};
            return;
        }
        r = here ++> Recipe(title=self.title.strip(), minutes=self.minutes);
        names: list[str] = [];
        for raw in self.ingredients {
            n = raw.strip().lower();
            if n and n not in names {
                names.append(n);
            }
        }
        for n in names {
            found = [i for i in [here -->[?:Ingredient]] if i.name == n];
            ing = found[0] if found else here ++> Ingredient(name=n);
            r +>:Uses:+> ing;
        }
        report recipe_view(r);
    }
}

walker:pub list_recipes {
    can listing with Root entry {
        report by_title([recipe_view(r) for r in [here -->[?:Recipe]]]);
    }
}

walker:pub recipes_with {
    has ingredient: str;
    has hits: list[dict[str, any]] = [];

    can start with Root entry {
        want = self.ingredient.strip().lower();
        visit [i for i in [here -->[?:Ingredient]] if i.name == want];
    }

    can collect with Ingredient entry {
        self.hits = [recipe_view(r) for r in [here <-:Uses:<-]];
    }

    can finish with exit {
        report by_title(self.hits);
    }
}

walker:pub rate_recipe {
    has recipe_id: str;
    has stars: int;

    can rate with Root entry {
        if self.stars < 1 or self.stars > 5 {
            report {"error": "stars must be 1-5"};
            return;
        }
        for r in [here -->[?:Recipe]] {
            if jid(r) == self.recipe_id {
                r.stars_total += self.stars;
                r.stars_count += 1;
                report recipe_view(r);
                return;
            }
        }
        report {"error": "no such recipe"};
    }
}

walker:pub top_rated {
    has limit: int = 3;

    can rank with Root entry {
        rated = [recipe_view(r) for r in [here -->[?:Recipe]] if r.stars_count > 0];
        ranked = sorted(rated, key=lambda (v: dict[str, any]) -> tuple[float, str] { return (-v["rating"], v["title"]); });
        report ranked[:self.limit];
    }
}
