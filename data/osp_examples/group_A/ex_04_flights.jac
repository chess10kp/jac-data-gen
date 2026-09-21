"""Flight network: an edge type with its own method.

Each Flight edge stores a ticket price and knows how to normalize it
against the most expensive fare in the network.
"""

node Airport {
    has code: str = "";
}

edge Flight {
    has price: float = 0.0;

    def price_ratio(max_price: float) -> float {
        if max_price <= 0.0 {
            return 0.0;
        }
        return self.price / max_price;
    }
}

walker FareScout {
    has reports: list[float] = [];

    can start with Root entry {
        visit [-->];
    }

    can collect with Airport entry {
        legs = [edge ->:Flight:->];
        for leg in legs {
            self.reports.append(leg.price);
        }
        visit [-->];
    }
}

with entry {
    jfk = Airport(code="JFK");
    ord = Airport(code="ORD");
    den = Airport(code="DEN");
    lax = Airport(code="LAX");

    root ++> jfk;
    jfk +>: Flight(price=310.0) :+> ord;
    ord +>: Flight(price=185.5) :+> den;
    den +>: Flight(price=425.0) :+> lax;

    result = root spawn FareScout();
    priciest = max(result.reports) if result.reports else 1.0;

    for leg in [edge jfk ->:Flight:-> ord] + [edge ord ->:Flight:-> den] + [edge den ->:Flight:-> lax] {
        print(f"Fare {leg.price:.2f} is {leg.price_ratio(priciest):.2%} of the priciest leg");
    }
}
