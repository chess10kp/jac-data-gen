"""Bike-share dock service.

Graph (per operator account):
    root --> Station -Docked-> Bike
    root --> Rider  -Riding-> Bike
"""

node Station {
    has code: str;
    has capacity: int;
}

node Bike {
    has serial: str;
    has km: float = 0.0;
}

node Rider {
    has name: str;
}

edge Docked: Station --> Bike {}

edge Riding: Rider --> Bike {
    has since: int = 0;
}

def:pub add_station(code: str, capacity: int) -> Station {
    return root ++> Station(code=code, capacity=capacity);
}

def:pub add_bike(station: str, serial: str, km: float) -> bool {
    for s in [root -->[?:Station]] {
        if s.code == station and len([s ->:Docked:->]) < s.capacity {
            s +>:Docked():+> Bike(serial=serial, km=km);
            return True;
        }
    }
    return False;
}

# TODO: rent_bike, return_bike, network_status walker endpoints
