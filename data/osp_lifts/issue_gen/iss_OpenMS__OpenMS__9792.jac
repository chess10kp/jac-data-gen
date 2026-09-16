# pyOpenMS ownership-model lift: OpenMS/OpenMS#9792
# Spectra hold peak data; get_* returns owned copies, _view accessors alias
# and are flagged dead by structural ops (generation bump + live-flag sweep).
# Order is carried by an explicit pos field instead of edge removal, so the
# lift never needs disconnect.

node Peak {
    has mz: float;
    has intensity: float;
    has pos: int = 0;          # position within its spectrum
    has live: bool = True;     # view-lease validity flag
}

node Spectrum {
    has sid: str;
    has generation: int = 0;   # bumped by structural ops, invalidates views
}

edge Holds {}                  # Spectrum -> Peak
edge View {}                   # Spectrum -> aliased Peak (view lease)

graph mssim {
    has spectra: dict[str, Spectrum] = {};

    def add_spectrum(sid: str) -> Spectrum {
        sp = Spectrum(sid=sid);
        root ++> sp;
        self.spectra[sid] = sp;
        return sp;
    }

    def _ordered(sp: Spectrum) -> list[Peak] {
        # view of held peaks sorted by explicit position field
        raw: list[Peak] = [sp ->:Holds:->][?:Peak];
        return sorted(raw, key=lambda p: p.pos);
    }

    # get_peak: owned copy semantics (policy: get_* returns a copy)
    def get_peak(sid: str, idx: int) -> Peak | None {
        sp = self.spectra.get(sid);
        if sp is None { return None; }
        kids = self._ordered(sp);
        if idx < 0 { idx = len(kids) + idx; }
        if idx < 0 or idx >= len(kids) { return None; }
        p = kids[idx];
        return Peak(mz=p.mz, intensity=p.intensity);  # owned copy
    }

    # spectrum_peak_view: aliasing opt-in under the _view contract
    def spectrum_peak_view(sid: str, idx: int) -> Peak | None {
        sp = self.spectra.get(sid);
        if sp is None { return None; }
        kids = self._ordered(sp);
        if idx < 0 { idx = len(kids) + idx; }
        if idx < 0 or idx >= len(kids) { return None; }
        return kids[idx];  # alias
    }

    def add_peak(sid: str, mz: float, inten: float) -> bool {
        sp = self.spectra.get(sid);
        if sp is None { return False; }
        p = Peak(mz=mz, intensity=inten, pos=len(self._ordered(sp)));
        sp +>:Holds:+> p;
        self.invalidate(sp);
        return True;
    }

    # structural op: sort peaks by mz -> generation bump, views die
    def sort_peaks(sid: str) -> bool {
        sp = self.spectra.get(sid);
        if sp is None { return False; }
        kids = self._ordered(sp);
        ordered: list[Peak] = sorted(kids, key=lambda p: p.mz);
        for i in range(len(ordered)) {
            ordered[i].pos = i;
        }
        self.invalidate(sp);
        return True;
    }

    def peaks_sorted(sid: str) -> list[tuple[float, float]] {
        sp = self.spectra.get(sid);
        if sp is None { return []; }
        out: list[tuple[float, float]] = [];
        for p in self._ordered(sp) {
            out.append((p.mz, p.intensity));
        }
        return sorted(out);
    }

    def invalidate(sp: Spectrum) -> int {
        # cascade sweep: bump generation, kill view leases via live flags
        sp.generation = sp.generation + 1;
        n: int = 0;
        for v in [sp ->:View:->][?:Peak] {
            if v.live {
                v.live = False;
                n = n + 1;
            }
        }
        return n;
    }
}

walker RebindAudit {
    has claimed: dict[str, bool] = {};
    has audited: int = 0;

    can step with Spectrum entry {
        if here.sid in self.claimed { skip; }   # diamond revisits: claim + skip
        self.claimed[here.sid] = True;
        self.audited = self.audited + 1;
        print("audit", here.sid, "generation", here.generation);
        kids: list[Spectrum] = [];
        for nxt in [here ->:Holds:->][?:Spectrum] { kids.append(nxt); }
        for nxt in [root ->:Holds:->][?:Spectrum] { kids.append(nxt); }
        visit kids;
    }
}

with entry {
    g = mssim();
    a = g.add_spectrum("scan1");
    g.add_peak("scan1", 101.0, 500.0);
    g.add_peak("scan1", 100.5, 900.0);
    cp = g.get_peak("scan1", 0);
    print("owned copy intensity", cp.intensity);   # 900.0
    aliased = g.spectrum_peak_view("scan1", 0);
    print("alias mz before sort", aliased.mz);
    print("invalidated views", g.sort_peaks("scan1"));
    print("sorted", g.peaks_sorted("scan1"));
    wk = root spawn RebindAudit(claimed={});
    print("audited spectra", wk.audited);
}
