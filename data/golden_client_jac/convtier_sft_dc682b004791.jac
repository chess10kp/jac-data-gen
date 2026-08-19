edge RoadLeg {}
edge RailLeg {}
node Stop { has name: str; }

walker Transfers {
    has last: str = "";
    has switches: int = 0;
    can ride with Stop entry {
        road_next = [->:RoadLeg:->];
        rail_next = [->:RailLeg:->];
        if len(road_next) > 0 {
            if self.last != "" and self.last != "road" { self.switches += 1; }
            self.last = "road";
            visit road_next;
        } elif len(rail_next) > 0 {
            if self.last != "" and self.last != "rail" { self.switches += 1; }
            self.last = "rail";
            visit rail_next;
        }
    }
}

def transfer_count(spec: dict) -> int {
    legs: list = spec["legs"];
    if len(legs) == 0 { return 0; }
    reg: dict = {};
    for leg in legs { for nm in [leg[0], leg[1]] { if nm not in reg { reg[nm] = Stop(name=nm); } } }
    for leg in legs {
        if leg[2] == "road" { reg[leg[0]] +>:RoadLeg:+> reg[leg[1]]; }
        else { reg[leg[0]] +>:RailLeg:+> reg[leg[1]]; }
    }
    wk = reg[legs[0][0]] spawn Transfers();
    return wk.switches;
}

with entry {
    print(transfer_count({'legs': [['a', 'b', 'road'], ['b', 'c', 'rail'], ['c', 'd', 'road']]}));
}
