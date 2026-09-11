"""Media asset pipeline, lifted to OSP.

Folders form a ParentFolder hierarchy; assets are linked to folders by
StoredIn cross-links and to their sources by DerivedFrom edges. Folder
quality aggregates are incrementally maintained. Purge follows the
two-phase protocol: a walker collects the derivative closure once-only,
the facade severs edges and retires assets outside the walk, then each
purged asset's folder chain is adjusted. Cycle policy: derivation cycles
are pruned by a skip-guard (the source used a visited set).
"""
node Folder {
    has fid: str;
}

node Asset {
    has aid: str;
    has quality: int;
    has dead: bool = False;
}

"""Folder tree: parent +>:SubfolderOf... parent +>:ParentFolder:+> child."""
edge ParentFolder {}

"""Asset stored in folder."""
edge StoredIn {}

"""Derivation cross-link: derivative +>:DerivedFrom:+> source."""
edge DerivedFrom {}

walker DerivativeCollector {
    """Stack-equivalent closure over incoming DerivedFrom edges; the
    skip-guard keeps shared derivatives once-only."""
    has origin: str;
    has claimed: dict[str, bool] = {};
    has doomed: set[str] = set();

    can step with Asset entry {
        if here.aid in self.claimed {
            skip;
        }
        self.claimed[here.aid] = True;
        self.doomed.add(here.aid);
        visit [here <-:DerivedFrom:<-];
    }
}

walker FolderAssetCensus {
    """Collects live assets in the folder; descends ParentFolder edges
    only when include_sub is set (source flag semantics)."""
    has found: set[str] = set();
    has claimed: dict[str, bool] = {};
    has include_sub: bool = True;

    can step with Asset entry {
        if here.dead {
            skip;
        }
        self.found.add(here.aid);
    }
    can census with Folder entry {
        if here.fid in self.claimed {
            skip;
        }
        self.claimed[here.fid] = True;
        visit [->:StoredIn:->];
        if self.include_sub {
            visit [->:ParentFolder:->];
        }
    }
}

walker ScoreAscent {
    """Linear ascent over ParentFolder applying a score delta to the
    folder chain up to the root."""
    has pipeline: MediaPipeline;
    has delta: int;

    can step with Folder entry {
        self.pipeline.score[here.fid] = (
            self.pipeline.score.get(here.fid, 0) + self.delta
        );
        visit [here <-:ParentFolder:<-] else { disengage; }
    }
}

obj MediaPipeline {
    """Compatibility facade. Folder and asset ids are public API currency;
    lookup maps are domain state."""
    has by_fid: dict[str, Folder] = {};
    has by_aid: dict[str, Asset] = {};
    has src_of: dict[str, str] = {};
    has score: dict[str, int] = {};

    def add_folder(fid: str, parent: str | None = None) -> str {
        if fid in self.by_fid {
            raise ValueError("duplicate folder " + fid);
        }
        f := Folder(fid=fid);
        if parent is not None {
            p = self.by_fid[parent];
            p +>:ParentFolder:+> f;
        }
        self.by_fid[fid] = f;
        return fid;
    }

    """Two-phase add: the ascent walker applies the quality delta along
    the folder chain outside any collection walk."""
    def add_asset(aid: str, fid: str, quality: int = 0) -> None {
        if aid in self.by_aid {
            raise ValueError("duplicate asset " + aid);
        }
        a := Asset(aid=aid, quality=quality);
        self.by_fid[fid] +>:StoredIn:+> a;
        self.by_aid[aid] = a;
        self._adjust_score(fid, quality);
    }

    def _adjust_score(fid: str, delta: int) -> None {
        # spawn the linear ascent; it applies the delta along the chain
        self.by_fid[fid] spawn ScoreAscent(pipeline=self, delta=delta);
    }

    def derive(src_aid: str, dst_aid: str, fid: str, quality: int = 0) -> None {
        self.add_asset(dst_aid, fid, quality);
        self.src_of[dst_aid] = src_aid;
        self.by_aid[dst_aid] +>:DerivedFrom:+> self.by_aid[src_aid];
    }

    def derivatives_of(aid: str) -> list[str] {
        w: DerivativeCollector = self.by_aid[aid] spawn DerivativeCollector(
            origin=aid
        );
        return sorted(w.doomed - {aid});
    }

    def folder_assets(fid: str, include_sub: bool = True) -> list[str] {
        # include_sub=False restricts the census to {fid} itself
        w = self.by_fid[fid] spawn FolderAssetCensus(include_sub=include_sub);
        return sorted(w.found);
    }

    def folder_score(fid: str) -> int {
        return self.score.get(fid, 0);
    }

    """Two-phase purge. Phase 1 collects the derivative closure; phase 2
    severs every edge touching the purged set and adjusts each purged
    asset's own folder chain by its quality."""
    def purge(aid: str) -> list[str] {
        if aid not in self.by_aid {
            raise KeyError(aid);
        }
        w: DerivativeCollector = self.by_aid[aid] spawn DerivativeCollector(
            origin=aid
        );
        doomed: set[str] = w.doomed;
        for d in doomed {
            a = self.by_aid.pop(d);
            a.dead = True;
            self.src_of.pop(d, None);
            # locate home folder before severing links
            home: Folder | None = None;
            homes: list[Folder] = [a <-:StoredIn:<-];
            if len(homes) > 0 {
                home = homes[0];
            }
            # sever derivation and storage edges
            outs = [a ->:DerivedFrom:->];
            for o in outs {
                a del ->:DerivedFrom:-> o;
            }
            ins = [a <-:DerivedFrom:<-];
            for i in ins {
                i del ->:DerivedFrom:-> a;
            }
            for f in homes {
                f del ->:StoredIn:-> a;
            }
            # ancestor-aware score adjustment along this asset's chain
            if home is not None {
                self._adjust_score(home.fid, -a.quality);
            }
        }
        return sorted(doomed);
    }
}
