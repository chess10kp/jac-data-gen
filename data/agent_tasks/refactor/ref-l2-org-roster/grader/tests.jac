import from roster { hire, manager_of, direct_reports, team_cost, peers, transfer, fire }

def staff {
    hire("ada", 300, "");
    hire("grace", 200, "ada");
    hire("linus", 150, "ada");
    hire("ken", 120, "grace");
    hire("barbara", 110, "grace");
    hire("dennis", 100, "linus");
}

test "hiring needs a unique name and a known manager" {
    assert hire("ada", 300, "");
    assert not hire("ada", 10, "");
    assert not hire("bob", 100, "zed");
    assert hire("bob", 100, "ada");
    assert hire("eve", 90, "");
    assert manager_of("bob") == "ada";
    assert manager_of("ada") == "";
    assert manager_of("zed") == "";
}

test "direct reports and team cost" {
    staff();
    assert direct_reports("ada") == ["grace", "linus"];
    assert direct_reports("grace") == ["barbara", "ken"];
    assert len(direct_reports("ken")) == 0;
    assert len(direct_reports("zed")) == 0;
    assert team_cost("grace") == 430;
    assert team_cost("ken") == 120;
    assert team_cost("ada") == 650;
    assert team_cost("zed") == 0;
}

test "peers share a manager" {
    staff();
    hire("eve", 90, "");
    assert peers("ken") == ["barbara"];
    assert peers("grace") == ["linus"];
    assert len(peers("dennis")) == 0;
    assert peers("ada") == ["eve"];
    assert len(peers("zed")) == 0;
}

test "transfer moves someone under a new manager" {
    staff();
    assert not transfer("zed", "ada");
    assert not transfer("ken", "zed");
    assert not transfer("ken", "ken");
    assert transfer("ken", "linus");
    assert manager_of("ken") == "linus";
    assert direct_reports("grace") == ["barbara"];
    assert direct_reports("linus") == ["dennis", "ken"];
    assert team_cost("linus") == 370;
    assert transfer("grace", "");
    assert manager_of("grace") == "";
    assert direct_reports("ada") == ["linus"];
    assert peers("grace") == ["ada"];
}

test "firing hands the team to the next manager up" {
    staff();
    assert not fire("zed");
    assert fire("grace");
    assert manager_of("ken") == "ada";
    assert manager_of("barbara") == "ada";
    assert direct_reports("ada") == ["barbara", "ken", "linus"];
    assert team_cost("ada") == 680;
    assert not hire("x", 1, "grace");
    assert fire("ada");
    assert manager_of("linus") == "";
    assert peers("linus") == ["barbara", "ken"];
    assert hire("grace", 50, "linus");
}
