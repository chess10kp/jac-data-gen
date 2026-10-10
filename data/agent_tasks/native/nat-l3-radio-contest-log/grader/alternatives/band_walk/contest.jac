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

    can start with Root entry {
        matching = [lg for lg in [-->[?:BandLog]] if lg.band.name == self.band.name];
        if matching {
            visit matching[0];
        } else {
            visit here ++> BandLog(band=self.band);
        }
    }

    can log with BandLog entry {
        sign = self.call.upper();
        for q in [here -->[?:Qso]] {
            if q.call == sign {
                report "dupe";
                disengage;
            }
        }
        here +>:Logged():+> Qso(call=sign, minute=self.minute, zone=self.zone);
        report "ok";
    }
}

walker Score {
    has qsos: int = 0;
    has mults: int = 0;

    can start with Root entry {
        all_qsos = [-->[?:BandLog] ->:Logged:->[?:Qso]];
        self.qsos = len(all_qsos);
        distinct: list[int] = [];
        for q in all_qsos {
            if q.zone not in distinct {
                distinct.append(q.zone);
            }
        }
        self.mults = len(distinct);
        report self.qsos * self.mults;
    }
}

walker BandSummary {
    can start with Root entry {
        report {lg.band.name: len([lg -->[?:Qso]]) for lg in [-->[?:BandLog]]};
    }
}
