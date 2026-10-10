"""Radio contest logbook: contacts per band, scored as contacts x distinct zones."""

enum Band {
    B80 = "80m",
    B40 = "40m",
    B20 = "20m",
    B10 = "10m"
}

glob BAND_ORDER: list[Band] = [Band.B80, Band.B40, Band.B20, Band.B10];

node BandLog {
    has band: Band;
}

node Station {
    has call: str;
}

edge Worked: BandLog --> Station {
    has minute: int;
    has zone: int;
}

"""Visit every band log of a logbook and gather contact minutes and zones."""
walker Tally {
    has zones: list[int] = [];
    has minutes: list[int] = [];

    can start with Logbook entry {
        visit [-->[?:BandLog]];
    }

    can read with BandLog entry {
        for qso in [edge here ->:Worked:->] {
            self.zones.append(qso.zone);
            self.minutes.append(qso.minute);
        }
    }
}

def band_of(label: str) -> Band | None {
    for b in BAND_ORDER {
        if b.value == label {
            return b;
        }
    }
    return None;
}

node Logbook {
    has callsign: str;

    def book(b: Band) -> BandLog {
        found = [lg for lg in [self -->[?:BandLog]] if lg.band == b];
        return found[0] if found else self ++> BandLog(band=b);
    }

    def station(sign: str) -> Station | None {
        found = [self -->[?:Station, call == sign]];
        return found[0] if found else None;
    }

    def log(call: str, band: str, minute: int, zone: int) -> str {
        b = band_of(band);
        if b is None {
            return "bad band";
        }
        sign = call.upper();
        bl = self.book(b);
        if [bl ->:Worked:->[?:Station, call == sign]] {
            return "dupe";
        }
        st = self.station(sign);
        if st is None {
            st = self ++> Station(call=sign);
        }
        bl +>:Worked(minute=minute, zone=zone):+> st;
        return "ok";
    }

    def score() -> int {
        t = self spawn Tally();
        distinct = sorted(set(t.zones));
        return len(t.zones) * len(distinct);
    }

    def band_counts() -> list[str] {
        out: list[str] = [];
        for b in BAND_ORDER {
            for bl in [lg for lg in [self -->[?:BandLog]] if lg.band == b] {
                n = len([bl ->:Worked:->]);
                if n > 0 {
                    out.append(f"{b.value}:{n}");
                }
            }
        }
        return out;
    }

    def worked_on(call: str) -> list[str] {
        st = self.station(call.upper());
        if st is None {
            return [];
        }
        seen = [bl.band for bl in [st <-:Worked:<-]];
        return [b.value for b in BAND_ORDER if b in seen];
    }

    def busiest_zone() -> int {
        zones = (self spawn Tally()).zones;
        best = -1;
        for z in sorted(zones) {
            if best == -1 or zones.count(z) > zones.count(best) {
                best = z;
            }
        }
        return best;
    }

    def in_window(start: int, end: int) -> int {
        return len([m for m in (self spawn Tally()).minutes if start <= m and m < end]);
    }
}
