import from tally { log_sighting, site_total, site_ranking, sites_for, last_seen, scarce }

def seed -> None {
    log_sighting("marsh", "heron", 2, 3);
    log_sighting("marsh", "teal", 5, 1);
    log_sighting("marsh", "heron", 3, 7);
    log_sighting("wood", "jay", 4, 2);
    log_sighting("wood", "heron", 1, 4);
    log_sighting("dune", "teal", 2, 9);
    log_sighting("dune", "heron", 6, 2);
}

test "counts must be positive" {
    assert not log_sighting("marsh", "heron", 0, 1);
    assert not log_sighting("marsh", "heron", -3, 1);
    assert site_total("marsh") == 0;
    assert len(sites_for("heron")) == 0;
    assert log_sighting("marsh", "heron", 1, 1);
    assert site_total("marsh") == 1;
}

test "site totals accumulate" {
    seed();
    assert site_total("marsh") == 10;
    assert site_total("wood") == 5;
    assert site_total("dune") == 8;
    assert site_total("nowhere") == 0;
}

test "ranking by total then name" {
    seed();
    assert site_ranking("marsh") == ["heron", "teal"];
    log_sighting("marsh", "teal", 1, 2);
    log_sighting("marsh", "avocet", 6, 2);
    assert site_ranking("marsh") == ["avocet", "teal", "heron"];
    assert site_ranking("wood") == ["jay", "heron"];
    assert len(site_ranking("nowhere")) == 0;
}

test "where and when a species was seen" {
    seed();
    assert sites_for("heron") == ["dune", "marsh", "wood"];
    assert sites_for("teal") == ["dune", "marsh"];
    assert len(sites_for("owl")) == 0;
    assert last_seen("heron") == 7;
    log_sighting("marsh", "heron", 1, 5);
    assert last_seen("heron") == 7;
    assert last_seen("teal") == 9;
    assert last_seen("owl") == -1;
}

test "scarce species" {
    seed();
    assert scarce(1) == ["jay"];
    assert scarce(2) == ["jay", "teal"];
    assert scarce(3) == ["heron", "jay", "teal"];
    assert len(scarce(0)) == 0;
}
