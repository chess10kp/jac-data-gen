"""Neighborhood buddies: bidirectional connections.

Friendship is mutual, so Buddy edges are created with `<+: ... :+>`,
which links both directions at once. Two walkers start at opposite
houses and each one greets every distinct house it can reach -- the
`met` list guards against bouncing back and forth across the
bidirectional edge forever.
"""

node House {
    has owner: str = "";
}

edge Buddy {
    has since: int = 2021;
}

walker Greeter {
    has who: str = "";
    has met: list[str] = [];
    has reports: list[str] = [];

    can greet with House entry {
        if here.owner not in self.met {
            self.met.append(here.owner);
            print(f"{self.who} waves hello to {here.owner}'s house");
            report here.owner;
            visit [-->];
        }
    }
}

with entry {
    ana_house = House(owner="Ana");
    leo_house = House(owner="Leo");

    root ++> ana_house;
    root ++> leo_house;

    # One statement creates BOTH Ana->Leo and Leo->Ana buddy edges.
    ana_house <+: Buddy(since=2023) :+> leo_house;

    ana_side = ana_house spawn Greeter(who="Ana");
    leo_side = leo_house spawn Greeter(who="Leo");

    print(f"Ana greeted: {ana_side.reports}");
    print(f"Leo greeted: {leo_side.reports}");
}
