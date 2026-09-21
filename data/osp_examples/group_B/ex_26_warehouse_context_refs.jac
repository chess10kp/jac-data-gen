"""Warehouse packing stations.

Demonstrates the three spatial references side by side: inside a walker
ability ``self`` is the robot and ``here`` is the station being
visited, while inside a node ability ``self`` is the station and
``visitor`` is the robot that triggered it.
"""

node PackingStation {
    has station_id: str;
    has boxes_packed: int = 0;

    # Node-side view: self = this station, visitor = the robot.
    can announce with Robot entry {
        print(f"[station {self.station_id}] serving robot {visitor.callsign}");
        self.boxes_packed += 1;
    }
}

walker Robot {
    has callsign: str;
    has stops: int = 0;

    can start with Root entry {
        print(f"[robot {self.callsign}] rolling out from root");
        visit [-->];
    }

    # Walker-side view: self = this robot, here = current station.
    can work with PackingStation entry {
        self.stops += 1;
        print(f"[robot {self.callsign}] stop #{self.stops} at {here.station_id}");
        visit [-->];
    }
}

with entry {
    s1 = PackingStation(station_id="S1");
    s2 = PackingStation(station_id="S2");
    s3 = PackingStation(station_id="S3");
    root ++> s1 ++> s2 ++> s3;

    unit7 = Robot(callsign="UNIT-7");
    root spawn unit7;

    print(f"station totals: S1={s1.boxes_packed} S2={s2.boxes_packed} "
          f"S3={s3.boxes_packed}; robot made {unit7.stops} stops");
}
