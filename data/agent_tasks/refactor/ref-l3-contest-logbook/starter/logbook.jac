"""Radio contest logbook: contacts per band, scored as contacts x distinct zones."""

obj Logbook {
    has callsign: str;
    has bands: list[str] = ["80m", "40m", "20m", "10m"];
    has calls: dict[str, list[str]] = {};
    has minute_of: dict[str, int] = {};
    has zone_of: dict[str, int] = {};

    def log(call: str, band: str, minute: int, zone: int) -> str {
        if band not in self.bands {
            return "bad band";
        }
        sign = call.upper();
        if band not in self.calls {
            self.calls[band] = [];
        }
        if sign in self.calls[band] {
            return "dupe";
        }
        self.calls[band].append(sign);
        self.minute_of[band + "/" + sign] = minute;
        self.zone_of[band + "/" + sign] = zone;
        return "ok";
    }

    def score() -> int {
        qsos = 0;
        zones: list[int] = [];
        for key in self.zone_of {
            qsos += 1;
            if self.zone_of[key] not in zones {
                zones.append(self.zone_of[key]);
            }
        }
        return qsos * len(zones);
    }

    def band_counts() -> list[str] {
        out: list[str] = [];
        for b in self.bands {
            if b in self.calls and len(self.calls[b]) > 0 {
                out.append(b + ":" + str(len(self.calls[b])));
            }
        }
        return out;
    }

    def worked_on(call: str) -> list[str] {
        sign = call.upper();
        out: list[str] = [];
        for b in self.bands {
            if b in self.calls and sign in self.calls[b] {
                out.append(b);
            }
        }
        return out;
    }

    def busiest_zone() -> int {
        best = -1;
        best_n = 0;
        for key in self.zone_of {
            z = self.zone_of[key];
            n = 0;
            for other in self.zone_of {
                if self.zone_of[other] == z {
                    n += 1;
                }
            }
            if n > best_n or (n == best_n and z < best) {
                best = z;
                best_n = n;
            }
        }
        return best;
    }

    def in_window(start: int, end: int) -> int {
        n = 0;
        for key in self.minute_of {
            if start <= self.minute_of[key] and self.minute_of[key] < end {
                n += 1;
            }
        }
        return n;
    }
}
