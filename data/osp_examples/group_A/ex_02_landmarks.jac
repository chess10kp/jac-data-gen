"""Hiking trail: plain waypoints with no data, used purely as stops.

The trail is a chain of bare waypoints between a trailhead and a
summit. The waypoints carry no fields at all -- all the interesting
state (how many stops were made) lives on the hiker walker.
"""

node Waypoint { }

walker Hiker {
    has stops: int = 0;

    can start with Root entry {
        print("Leaving the trailhead");
        visit [-->];
    }

    can pass_through with Waypoint entry {
        self.stops += 1;
        print(f"Passed stop #{self.stops}");
        visit [-->];
    }

    can done with Waypoint exit {
        if self.stops >= 3 {
            print(f"Trail complete after {self.stops} waypoints");
        }
    }
}

with entry {
    root ++> Waypoint() ++> Waypoint() ++> Waypoint();
    root spawn Hiker();
}
