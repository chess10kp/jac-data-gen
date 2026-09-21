"""Price out direct flights leaving each airport.

Legs carry their own data -- flight number and fare. The planner pulls
the edge objects themselves rather than the destination nodes, so it
can print fares without a second lookup.
"""

node Airport {
    has code: str;
    has city: str;
}

edge Leg {
    has number: str;
    has fare: float;
}

walker FareBoard {
    can start with Root entry {
        visit [-->];
    }

    can board with Airport entry {
        # Edge objects instead of destinations: attributes ride along
        legs = [edge -->];

        if not legs {
            print(f"{here.code}: no departures");
        }
        # Connection order guarantees legs[i] and dests[i] describe the same flight
        dests = [->:Leg:->];
        for i in range(len(dests)) {
            print(f"{here.code} -> {dests[i].code} on {legs[i].number} for ${legs[i].fare}");
        }
        visit [-->];
    }
}

with entry {
    sfo = Airport(code="SFO", city="San Francisco");
    den = Airport(code="DEN", city="Denver");
    ord = Airport(code="ORD", city="Chicago");
    jfk = Airport(code="JFK", city="New York");

    sfo +>: Leg(number="UA-214", fare=189.0) :+> den;
    den +>: Leg(number="UA-411", fare=129.5) :+> ord;
    ord +>: Leg(number="AA-902", fare=97.25) :+> jfk;

    root ++> sfo;
    root spawn FareBoard();
}
