import uuid;
import from endpoints { add_recipe, list_recipes, recipes_with, rate_recipe, top_rated }

def get(x: any, k: str) -> any {
    return x[k] if isinstance(x, dict) else getattr(x, k);
}

def flat(rs: list[any]) -> list[any] {
    if len(rs) == 1 and isinstance(rs[0], list) {
        return rs[0];
    }
    return rs;
}

def add(t: str, ings: list[str], mins: int = 0) -> any {
    return (root spawn add_recipe(title=t, ingredients=ings, minutes=mins)).reports[0];
}

test "add normalizes ingredients" {
    t = "Soup " + uuid.uuid4().hex[:6];
    v = add(t, [" Leek", "potato ", "LEEK", ""], 40);
    assert get(v, "title") == t and get(v, "minutes") == 40;
    assert list(get(v, "ingredients")) == ["leek", "potato"];
    assert get(v, "rating") == 0.0 and get(v, "ratings") == 0;
    assert len(get(v, "id")) > 0;
    bad = (root spawn add_recipe(title="  ", ingredients=["x"])).reports[0];
    assert isinstance(bad, dict) and "error" in bad;
}

test "search by shared ingredient" {
    tag = uuid.uuid4().hex[:6];
    ing = "saffron" + tag;
    add("B " + tag, [ing, "rice"]);
    add("A " + tag, [ing.upper()]);
    add("C " + tag, ["rice"]);
    hits = [get(v, "title") for v in flat((root spawn recipes_with(ingredient=" " + ing + " ")).reports)];
    assert hits == ["A " + tag, "B " + tag];
    assert len(flat((root spawn recipes_with(ingredient="unobtainium" + tag)).reports)) == 0;
    everything = [get(v, "title") for v in flat((root spawn list_recipes()).reports)];
    mine = [t for t in everything if t.endswith(tag)];
    assert mine == ["A " + tag, "B " + tag, "C " + tag];
}

test "ratings and top rated" {
    tag = uuid.uuid4().hex[:6];
    a = add("Alpha " + tag, ["x" + tag]);
    b = add("Beta " + tag, ["x" + tag]);
    c = add("Gamma " + tag, ["x" + tag]);
    root spawn rate_recipe(recipe_id=get(a, "id"), stars=5);
    v = (root spawn rate_recipe(recipe_id=get(a, "id"), stars=4)).reports[0];
    assert abs(get(v, "rating") - 4.5) < 1e-9 and get(v, "ratings") == 2;
    root spawn rate_recipe(recipe_id=get(b, "id"), stars=5);
    root spawn rate_recipe(recipe_id=get(b, "id"), stars=4);
    root spawn rate_recipe(recipe_id=get(c, "id"), stars=5);
    bad = (root spawn rate_recipe(recipe_id=get(c, "id"), stars=0)).reports[0];
    assert isinstance(bad, dict) and "error" in bad;
    ghost = (root spawn rate_recipe(recipe_id="nope" + tag, stars=3)).reports[0];
    assert isinstance(ghost, dict) and "error" in ghost;
    top = [get(x, "title") for x in flat((root spawn top_rated(limit=1000)).reports) if get(x, "title").endswith(tag)];
    assert top == ["Gamma " + tag, "Alpha " + tag, "Beta " + tag];
}
