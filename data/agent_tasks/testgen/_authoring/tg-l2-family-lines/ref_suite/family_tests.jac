import from family { Person, ParentOf, Descendants, Ancestors, FirstCousins }

def child(a: Person, b: Person | None, name: str, born: int) -> Person {
    c = Person(name=name, born=born);
    a +>:ParentOf:+> c;
    if b is not None {
        b +>:ParentOf:+> c;
    }
    return c;
}

def clan -> dict[str, Person] {
    p: dict[str, Person] = {};
    p["oz"] = Person(name="Oz", born=1900);
    p["una"] = Person(name="Una", born=1902);
    p["ben"] = child(p["oz"], p["una"], "Ben", 1930);
    p["cat"] = child(p["oz"], p["una"], "Cat", 1930);
    p["dan"] = child(p["oz"], None, "Dan", 1935);
    p["eve"] = Person(name="Eve", born=1931);
    p["fay"] = child(p["ben"], p["eve"], "Fay", 1960);
    p["gus"] = child(p["ben"], p["eve"], "Gus", 1958);
    p["hal"] = child(p["ben"], None, "Hal", 1962);
    p["ivy"] = child(p["cat"], None, "Ivy", 1959);
    p["jon"] = child(p["dan"], None, "Jon", 1961);
    p["kit"] = child(p["fay"], p["jon"], "Kit", 1990);
    return p;
}

test "descendants sorted by birth year then name" {
    p = clan();
    w = p["ben"] spawn Descendants();
    assert len(w.reports) == 1;
    assert list(w.reports[0]) == ["Gus", "Fay", "Hal", "Kit"];
}

test "descendants reached twice are listed once" {
    p = clan();
    d = list((p["oz"] spawn Descendants()).reports[0]);
    assert d == ["Ben", "Cat", "Dan", "Gus", "Ivy", "Fay", "Jon", "Hal", "Kit"];
}

test "descendants of a leaf and exclude the start person" {
    p = clan();
    assert len((p["kit"] spawn Descendants()).reports[0]) == 0;
    assert "Ben" not in list((p["ben"] spawn Descendants()).reports[0]);
}

test "ancestors through every parent, alphabetical" {
    p = clan();
    w = p["kit"] spawn Ancestors();
    assert len(w.reports) == 1;
    assert list(w.reports[0]) == ["Ben", "Dan", "Eve", "Fay", "Jon", "Oz", "Una"];
}

test "ancestors of a root person and of a one-parent child" {
    p = clan();
    assert len((p["oz"] spawn Ancestors()).reports[0]) == 0;
    assert list((p["hal"] spawn Ancestors()).reports[0]) == ["Ben", "Oz", "Una"];
}

test "first cousins exclude siblings and half siblings" {
    p = clan();
    assert list((p["fay"] spawn FirstCousins()).reports[0]) == ["Ivy", "Jon"];
    assert list((p["hal"] spawn FirstCousins()).reports[0]) == ["Ivy", "Jon"];
    assert list((p["ivy"] spawn FirstCousins()).reports[0]) == ["Fay", "Gus", "Hal", "Jon"];
}

test "people without grandparents have no cousins" {
    p = clan();
    assert len((p["ben"] spawn FirstCousins()).reports[0]) == 0;
    assert len((p["oz"] spawn FirstCousins()).reports[0]) == 0;
}

test "each walker reports once" {
    p = clan();
    assert len((p["fay"] spawn FirstCousins()).reports) == 1;
    assert len((p["oz"] spawn Descendants()).reports) == 1;
    assert len((p["kit"] spawn Ancestors()).reports) == 1;
}
