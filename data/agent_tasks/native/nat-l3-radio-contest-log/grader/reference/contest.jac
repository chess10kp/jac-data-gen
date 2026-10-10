"""Contest logbook: one BandLog per Band on root; BandLog -Logged-> Qso."""

enum Band {
    B80M,
    B40M,
    B20M,
    B10M
}

node BandLog {
    has band: Band;
}

node Qso {
    has call: str;
    has minute: int;
    has zone: int;
}

edge Logged: BandLog --> Qso {}

walker LogQso {
    has call: str;
    has band: Band;
    has minute: int;
    has zone: int;

    can log with Root entry {
        sign = self.call.upper();
        logs = [root -->[?:BandLog, band == self.band]];
        book = logs[0] if logs else root ++> BandLog(band=self.band);
        if [book ->:Logged:->[?:Qso, call == sign]] {
            report "dupe";
            return;
        }
        book +>:Logged():+> Qso(call=sign, minute=self.minute, zone=self.zone);
        report "ok";
    }
}

walker Score {
    has qsos: int = 0;
    has mults: int = 0;
    has zones: set[int] = set();

    can start with Root entry {
        visit [-->[?:BandLog]];
    }

    can tally with BandLog entry {
        for q in [here ->:Logged:->] {
            self.qsos += 1;
            self.zones.add(q.zone);
        }
    }

    can finish with Root exit {
        self.mults = len(self.zones);
        report self.qsos * self.mults;
    }
}

walker BandSummary {
    has counts: dict[str, int] = {};

    can start with Root entry {
        visit [-->[?:BandLog]];
    }

    can tally with BandLog entry {
        self.counts[here.band.name] = len([here ->:Logged:->]);
    }

    can finish with Root exit {
        report self.counts;
    }
}
