"""River catchment model. FlowsInto edges point downstream."""

node Reach {
    has name: str;
    has load_kg: float = 0.0;   # pollutant load entering this reach per day
}

node Station {
    has code: str;
}

edge FlowsInto: Reach --> Reach {
    has seasonal: bool = False;
}

edge Samples: Station --> Reach {}

def connect_reach(up: Reach, down: Reach, seasonal: bool) {
    up +>:FlowsInto(seasonal=seasonal):+> down;
}
