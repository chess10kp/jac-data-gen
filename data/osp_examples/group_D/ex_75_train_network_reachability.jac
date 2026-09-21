"""Train-network reachability with line changes counted.

Stations are connected by Track edges that carry the name of the line
running over them. Riders spawn as walkers hop-by-hop; a rider staying on
the same line costs nothing, while switching lines costs one change. Each
station remembers the fewest changes it has been reached with so far, so
worse routes are pruned and the final number at the destination is the
best possible.
"""

node Station {
    has name: str;
    has best_changes: int = 9999;  # fewest line changes to reach here
}

edge Track: Station --> Station {
    has line: str;
}

walker LineRider {
    has dest: str;
    has changes: int = 0;
    has line: str = "";  # line currently ridden ("" before boarding)

    can ride with Station entry {
        if self.changes >= here.best_changes {
            skip;  # we reached this station no better than before
        }
        here.best_changes = self.changes;

        if here.name == self.dest {
            print(f"{here.name} is reachable with {self.changes} "
                  f"line change(s).");
            disengage;  # only this rider stops; sibling riders continue
        }

        tracks = [edge ->:Track:->];
        stops = [->:Track:->];

        for i in range(len(tracks)) {
            next_line = tracks[i].line;
            extra = 0;
            if self.line != "" and next_line != self.line {
                extra = 1;  # switching lines at this station
            }
            next_stop = stops[i];
            next_stop spawn LineRider(
                dest=self.dest,
                changes=self.changes + extra,
                line=next_line,
            );
        }
    }
}

with entry {
    for stale in [root -->][?:Station] {
        del stale;
    }

    airport = Station(name="Airport");
    central = Station(name="Central");
    rivergate = Station(name="Rivergate");
    oldtown = Station(name="Oldtown");
    stadium = Station(name="Stadium");
    harbor = Station(name="Harbor");
    island = Station(name="Island");  # not connected to anything

    # Red line: Airport - Central - Rivergate - Oldtown
    airport +>: Track(line="Red") :+> central;
    central +>: Track(line="Red") :+> rivergate;
    rivergate +>: Track(line="Red") :+> oldtown;
    oldtown +>: Track(line="Red") :+> rivergate;
    rivergate +>: Track(line="Red") :+> central;
    central +>: Track(line="Red") :+> airport;

    # Blue line crosses at Central: Central - Stadium - Harbor
    central +>: Track(line="Blue") :+> stadium;
    stadium +>: Track(line="Blue") :+> harbor;
    harbor +>: Track(line="Blue") :+> stadium;
    stadium +>: Track(line="Blue") :+> central;

    # Green shuttle between Rivergate and Stadium (another transfer point).
    rivergate +>: Track(line="Green") :+> stadium;
    stadium +>: Track(line="Green") :+> rivergate;

    airport spawn LineRider(dest="Harbor");

    if harbor.best_changes >= 9999 {
        print(f"{harbor.name} is unreachable from the network.");
    } else {
        summary = harbor.best_changes;
        print(f"Minimum line changes to {harbor.name}: {summary}");
    }

    if island.best_changes >= 9999 {
        print(f"{island.name} is unreachable (no tracks at all).");
    }
}
