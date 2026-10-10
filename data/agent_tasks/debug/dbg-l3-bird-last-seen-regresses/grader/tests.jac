import from survey { Site, Species, Sighted, LogSighting, SiteList, Scarce }

def log(site: str, sp: str, n: int, day: int) -> bool {
    return (root spawn LogSighting(site=site, species=sp, count=n, day=day)).reports[0];
}

def edge_for(site: str, sp: str) -> Sighted {
    s = [root -->[?:Site, name == site]][0];
    b = [root -->[?:Species, name == sp]][0];
    return [edge s ->:Sighted:-> b][0];
}

test "first sighting creates nodes and edge" {
    assert log("Marsh", "Heron", 2, 5) == True;
    assert len([root -->[?:Site]]) == 1;
    assert len([root -->[?:Species]]) == 1;
    e = edge_for("Marsh", "Heron");
    assert e.total == 2;
    assert e.last_day == 5;
}

test "repeat sightings accumulate on one edge" {
    log("Marsh", "Heron", 2, 5);
    log("Marsh", "Heron", 3, 9);
    log("Marsh", "Heron", 1, 7);
    s = [root -->[?:Site, name == "Marsh"]][0];
    assert len([edge s ->:Sighted:->]) == 1;
    e = edge_for("Marsh", "Heron");
    assert e.total == 6;
    assert e.last_day == 9;
}

test "shared species node across sites" {
    log("Marsh", "Heron", 1, 1);
    log("Wood", "Heron", 1, 1);
    log("Wood", "Jay", 1, 1);
    assert len([root -->[?:Species]]) == 2;
    assert len([root -->[?:Site]]) == 2;
}

test "non positive counts are ignored entirely" {
    assert log("Dune", "Plover", 0, 1) == False;
    assert log("Dune", "Plover", -2, 1) == False;
    assert len([root -->[?:Site]]) == 0;
    assert len([root -->[?:Species]]) == 0;
}

test "site list by total desc then name" {
    log("Wood", "Jay", 4, 1);
    log("Wood", "Wren", 4, 1);
    log("Wood", "Owl", 1, 1);
    log("Wood", "Robin", 2, 1);
    log("Wood", "Robin", 5, 2);
    log("Marsh", "Coot", 50, 1);
    w = root spawn SiteList(site="Wood");
    assert len(w.reports) == 1;
    assert w.reports[0] == ["Robin", "Jay", "Wren", "Owl"];
    assert len((root spawn SiteList(site="Nowhere")).reports[0]) == 0;
}

test "scarce species by distinct site count" {
    log("A", "Kite", 1, 1);
    log("A", "Kite", 1, 2);
    log("B", "Crow", 1, 1);
    log("C", "Crow", 1, 1);
    log("D", "Crow", 1, 1);
    log("B", "Finch", 1, 1);
    log("C", "Finch", 1, 1);
    assert (root spawn Scarce(max_sites=1)).reports[0] == ["Kite"];
    assert (root spawn Scarce(max_sites=2)).reports[0] == ["Finch", "Kite"];
    assert (root spawn Scarce(max_sites=3)).reports[0] == ["Crow", "Finch", "Kite"];
}
