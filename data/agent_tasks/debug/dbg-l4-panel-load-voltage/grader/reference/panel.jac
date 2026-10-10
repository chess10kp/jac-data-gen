"""Home electrical panel: Breaker -Feeds-> Outlet <-PluggedInto- Appliance."""

node Breaker {
    has label: str;
    has amps: int;      # rating
}

node Outlet {
    has room: str;
}

node Appliance {
    has name: str;
    has watts: int;
    has on: bool = True;
}

edge Feeds: Breaker --> Outlet {}

edge PluggedInto: Appliance --> Outlet {}

def breaker(label: str, amps: int) -> Breaker {
    return root ++> Breaker(label=label, amps=amps);
}

def outlet(b: Breaker, room: str) -> Outlet {
    o = Outlet(room=room);
    b +>:Feeds():+> o;
    return o;
}

def plug(o: Outlet, name: str, watts: int, on: bool) -> Appliance {
    a = Appliance(name=name, watts=watts, on=on);
    a +>:PluggedInto():+> o;
    return a;
}
