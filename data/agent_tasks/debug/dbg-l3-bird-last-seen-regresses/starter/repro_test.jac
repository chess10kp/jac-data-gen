import from survey { Site, Species, Sighted, LogSighting }

test "late card does not move last_day backwards" {
    root spawn LogSighting(site="Marsh", species="Heron", count=2, day=3);
    root spawn LogSighting(site="Marsh", species="Heron", count=1, day=1);
    s = [root -->[?:Site, name == "Marsh"]][0];
    e = [edge s ->:Sighted:->][0];
    assert e.total == 3;
    assert e.last_day == 3;
}
