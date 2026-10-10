import from survey { Site, Species, Sighted, site_named, species_named, LogSighting, SiteList, Scarce }

def log(site: str, sp: str, n: int, day: int) -> bool {
    return (root spawn LogSighting(site=site, species=sp, count=n, day=day)).reports[0];
}

def link(site: str, sp: str) -> Sighted {
    s = [root -->[?:Site, name == site]][0];
    b = [root -->[?:Species, name == sp]][0];
    return [edge s ->:Sighted:-> b][0];
}

test "site_named and species_named are get-or-create" {
    a = site_named("Fen");
    b = site_named("Fen");
    assert a == b;
    c = species_named("Rail");
    assert c == species_named("Rail");
    assert len([root -->[?:Site]]) == 1;
    assert len([root -->[?:Species]]) == 1;
}

test "a first sighting records count and day" {
    assert log("Bay", "Tern", 7, 3) == True;
    e = link("Bay", "Tern");
    assert e.total == 7;
    assert e.last_day == 3;
}

test "logging reports exactly once" {
    w = root spawn LogSighting(site="Bay", species="Tern", count=1, day=1);
    assert len(w.reports) == 1;
}

test "repeat sightings add up on a single edge" {
    log("Bay", "Tern", 2, 4);
    log("Bay", "Tern", 5, 6);
    s = [root -->[?:Site, name == "Bay"]][0];
    assert len([edge s ->:Sighted:->]) == 1;
    assert link("Bay", "Tern").total == 7;
}

test "last_day keeps the latest day even if logged out of order" {
    log("Bay", "Tern", 1, 10);
    log("Bay", "Tern", 1, 4);
    assert link("Bay", "Tern").last_day == 10;
    log("Bay", "Tern", 1, 12);
    assert link("Bay", "Tern").last_day == 12;
}

test "zero and negative counts are rejected without side effects" {
    assert log("Cliff", "Puffin", 0, 1) == False;
    assert log("Cliff", "Puffin", -1, 1) == False;
    assert len([root -->[?:Site]]) == 0;
    assert len([root -->[?:Species]]) == 0;
    assert log("Cliff", "Puffin", 1, 1) == True;
}

test "species shared across sites, sites shared across species" {
    log("North", "Gull", 1, 1);
    log("South", "Gull", 1, 1);
    log("North", "Skua", 1, 1);
    assert len([root -->[?:Species]]) == 2;
    assert len([root -->[?:Site]]) == 2;
    gull = [root -->[?:Species, name == "Gull"]][0];
    assert len([gull <-:Sighted:<-]) == 2;
}

test "site list orders by total descending" {
    log("Lake", "Coot", 3, 1);
    log("Lake", "Grebe", 9, 1);
    log("Lake", "Teal", 5, 1);
    w = root spawn SiteList(site="Lake");
    assert len(w.reports) == 1;
    assert w.reports[0] == ["Grebe", "Teal", "Coot"];
}

test "site list breaks ties by name and uses accumulated totals" {
    log("Lake", "Wigeon", 4, 1);
    log("Lake", "Avocet", 4, 1);
    log("Lake", "Coot", 1, 1);
    log("Lake", "Coot", 4, 2);
    log("Moor", "Grouse", 100, 1);
    assert (root spawn SiteList(site="Lake")).reports[0] == ["Coot", "Avocet", "Wigeon"];
}

test "unknown site lists nothing" {
    log("Lake", "Coot", 3, 1);
    w = root spawn SiteList(site="Desert");
    assert len(w.reports) == 1;
    assert len(w.reports[0]) == 0;
}

test "scarce counts distinct sites with an inclusive limit" {
    log("A", "Owl", 1, 1);
    log("A", "Owl", 1, 2);
    log("A", "Lark", 1, 1);
    log("B", "Lark", 1, 1);
    log("A", "Crow", 1, 1);
    log("B", "Crow", 1, 1);
    log("C", "Crow", 1, 1);
    assert len((root spawn Scarce(max_sites=0)).reports[0]) == 0;
    assert (root spawn Scarce(max_sites=1)).reports[0] == ["Owl"];
    assert (root spawn Scarce(max_sites=2)).reports[0] == ["Lark", "Owl"];
    w = root spawn Scarce(max_sites=5);
    assert len(w.reports) == 1;
    assert w.reports[0] == ["Crow", "Lark", "Owl"];
}
