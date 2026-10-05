node Location {
    has name: str;
    has risk: int = 0;
}

edge Road {}

walker build_city {

    can enter with Root entry {

        Downtown = root ++> Location(name="Downtown", risk=2);
        Hospital = root ++> Location(name="Hospital", risk=1);
        School = root ++> Location(name="School", risk=6);
        Shelter = root ++> Location(name="Shelter", risk=0);

        Downtown +>:Road:+> Hospital;
        Hospital +>:Road:+> Shelter;
        Downtown +>:Road:+> School;
        School +>:Road:+> Shelter;

        report "CITY GRAPH BUILT";
    }
}