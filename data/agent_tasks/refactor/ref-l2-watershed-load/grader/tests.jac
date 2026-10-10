import from catchment { upstream_reaches, upstream_load, headwaters }

def reaches -> list[dict[str, any]] {
    return [
        {"name": "spring", "load": 0.5},
        {"name": "brook", "load": 1.25},
        {"name": "mill", "load": 2.0},
        {"name": "ditch", "load": 4.0},
        {"name": "town", "load": 8.0},
        {"name": "estuary", "load": 16.0},
        {"name": "lake", "load": 32.0}
    ];
}

def flows -> list[dict[str, any]] {
    return [
        {"from": "spring", "to": "brook", "seasonal": False},
        {"from": "brook", "to": "mill", "seasonal": False},
        {"from": "brook", "to": "town", "seasonal": False},
        {"from": "mill", "to": "town", "seasonal": False},
        {"from": "ditch", "to": "town", "seasonal": True},
        {"from": "town", "to": "estuary", "seasonal": False},
        {"from": "ghost", "to": "lake", "seasonal": False}
    ];
}

test "upstream follows flows against the current" {
    assert upstream_reaches(reaches(), flows(), "town", False) == ["brook", "ditch", "mill", "spring", "town"];
    assert upstream_reaches(reaches(), flows(), "mill", False) == ["brook", "mill", "spring"];
    assert upstream_reaches(reaches(), flows(), "spring", False) == ["spring"];
    assert upstream_reaches(reaches(), flows(), "lake", False) == ["lake"];
    assert len(upstream_reaches(reaches(), flows(), "nowhere", False)) == 0;
}

test "dry season drops seasonal channels" {
    assert upstream_reaches(reaches(), flows(), "town", True) == ["brook", "mill", "spring", "town"];
    assert upstream_reaches(reaches(), flows(), "estuary", True) == ["brook", "estuary", "mill", "spring", "town"];
    assert upstream_load(reaches(), flows(), "town", True) == 11.75;
}

test "loads count each reach once even where channels rejoin" {
    assert upstream_load(reaches(), flows(), "town", False) == 15.75;
    assert upstream_load(reaches(), flows(), "estuary", False) == 31.75;
    assert upstream_load(reaches(), flows(), "mill", False) == 3.75;
    assert upstream_load(reaches(), flows(), "lake", False) == 32.0;
    assert upstream_load(reaches(), flows(), "nowhere", False) == 0.0;
}

test "headwaters have no inflow at all" {
    assert headwaters(reaches(), flows()) == ["ditch", "lake", "spring"];
    assert headwaters(reaches(), []) == ["brook", "ditch", "estuary", "lake", "mill", "spring", "town"];
    assert len(headwaters([], flows())) == 0;
    assert headwaters(reaches(), [{"from": "ditch", "to": "mill", "seasonal": True}]) == ["brook", "ditch", "estuary", "lake", "spring", "town"];
}
