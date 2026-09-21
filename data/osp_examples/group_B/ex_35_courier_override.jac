"""Parcel courier fleet.

``ExpressCourier`` inherits everything from ``Courier`` but overrides
the depot-delivery ability with priority handling; spawning both kinds
over the same depot chain shows the two behaviors side by side.
"""

node Depot {
    has depot_id: str;
    has parcels_waiting: int;
}

walker Courier {
    has name: str;
    has packages: int = 0;

    can start with Root entry {
        visit [-->];
    }

    can deliver with Depot entry {
        self.packages += here.parcels_waiting;
        print(f"[standard] {self.name} picked up {here.parcels_waiting} "
              f"parcel(s) at {here.depot_id}");
        visit [-->];
    }
}

walker ExpressCourier(Courier) {
    override can deliver with Depot entry {
        self.packages += here.parcels_waiting * 2;
        print(f"[PRIORITY] {self.name} expedited {here.parcels_waiting} "
              f"parcel(s) at {here.depot_id}");
        visit [-->];
    }
}

with entry {
    hub = Depot(depot_id="HUB", parcels_waiting=10);
    midtown = Depot(depot_id="MID", parcels_waiting=4);
    airport = Depot(depot_id="AIR", parcels_waiting=6);
    root ++> hub ++> midtown ++> airport;

    sam = Courier(name="Sam");
    result = root spawn sam;
    print(f"Sam moved {sam.packages} parcel(s) total");

    riley = ExpressCourier(name="Riley");
    root spawn riley;
    print(f"Riley moved {riley.packages} parcel(s) total");
}
