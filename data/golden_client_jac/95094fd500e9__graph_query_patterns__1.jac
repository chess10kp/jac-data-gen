node Room {
    has name: str;
}

edge Door {}

test "graph connections" {
    kitchen = Room(name="Kitchen");
    living = Room(name="Living Room");
    bedroom = Room(name="Bedroom");

    root ++> kitchen;
    kitchen +>: Door() :+> living;
    living +>: Door() :+> bedroom;

    # Test connections
    assert len([root -->]) == 1;
    assert len([kitchen -->]) == 1;
    assert len([living -->]) == 1;
    assert len([bedroom -->]) == 0;

    # Test connectivity
    assert living in [kitchen ->:Door:->];
    assert bedroom in [living ->:Door:->];
}
