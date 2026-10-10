import from family { Person, ParentOf, Descendants, Ancestors, FirstCousins }

def kid(p1: Person, p2: Person | None, name: str, born: int) -> Person {
    c = Person(name=name, born=born);
    p1 +>:ParentOf:+> c;
    if p2 is not None {
        p2 +>:ParentOf:+> c;
    }
    return c;
}

def build -> dict[str, Person] {
    g: dict[str, Person] = {};
    gpa = Person(name="Arthur", born=1930);
    gma = Person(name="Molly", born=1932);
    g["gpa"] = gpa; g["gma"] = gma;
    bill = kid(gpa, gma, "Bill", 1955);
    percy = kid(gpa, gma, "Percy", 1960);
    ginny = kid(gpa, gma, "Ginny", 1962);
    fleur = Person(name="Fleur", born=1957);
    harry = Person(name="Harry", born=1961);
    vic = kid(bill, fleur, "Victoire", 1980);
    dom = kid(bill, fleur, "Dominique", 1982);
    louis = kid(bill, fleur, "Louis", 1982);
    james = kid(ginny, harry, "James", 1984);
    al = kid(ginny, harry, "Albus", 1986);
    lily = kid(ginny, harry, "Lily", 1988);
    molly2 = kid(percy, None, "Molly2", 1985);
    # Harry's child from another relationship: half-sibling of James, not a cousin
    teddy = kid(harry, None, "Teddy", 1983);
    great = kid(vic, None, "Remus", 2005);
    g["bill"] = bill; g["ginny"] = ginny; g["vic"] = vic; g["james"] = james;
    g["lily"] = lily; g["harry"] = harry; g["great"] = great; g["teddy"] = teddy;
    return g;
}

test "descendants sorted by birth then name" {
    g = build();
    r = g["bill"] spawn Descendants();
    assert len(r.reports) == 1;
    assert list(r.reports[0]) == ["Victoire", "Dominique", "Louis", "Remus"];
    all_d = (g["gpa"] spawn Descendants()).reports[0];
    assert len(all_d) == 11;
    assert list(all_d[:3]) == ["Bill", "Percy", "Ginny"];
    assert all_d[-1] == "Remus";
    assert len((g["lily"] spawn Descendants()).reports[0]) == 0;
}

test "ancestors through both parents" {
    g = build();
    assert list((g["james"] spawn Ancestors()).reports[0]) == ["Arthur", "Ginny", "Harry", "Molly"];
    assert list((g["great"] spawn Ancestors()).reports[0]) == ["Arthur", "Bill", "Fleur", "Molly", "Victoire"];
    assert len((g["gpa"] spawn Ancestors()).reports[0]) == 0;
}

test "first cousins exclude siblings and half siblings" {
    g = build();
    assert list((g["james"] spawn FirstCousins()).reports[0]) == ["Dominique", "Louis", "Molly2", "Victoire"];
    assert list((g["vic"] spawn FirstCousins()).reports[0]) == ["Albus", "James", "Lily", "Molly2"];
    assert len((g["teddy"] spawn FirstCousins()).reports[0]) == 0;
    assert len((g["bill"] spawn FirstCousins()).reports[0]) == 0;
}

test "each walker reports once" {
    g = build();
    assert len((g["gpa"] spawn Descendants()).reports) == 1;
    assert len((g["james"] spawn Ancestors()).reports) == 1;
    assert len((g["james"] spawn FirstCousins()).reports) == 1;
}
