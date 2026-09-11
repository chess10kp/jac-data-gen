"""Media asset pipeline with derivative tracking.

Assets live in nested folders; each derived render points back at its
source asset. Purging an asset cascades to every derivative transitively,
and folder quality aggregates are maintained up the folder tree.

Hand-rolled machinery:
- parent/children pointers over the folder tree (C1)
- derivation adjacency dict with stack walks and visited guards (C2)
- queue-based cascade sweep plus ancestor aggregation (C5)
"""
class Folder {
    def init(self: Folder, fid: Any, parent: Any = None) -> object {
        self.fid = fid;
        self.parent = parent;
        self.children = [];
    }
}
class Asset {
    def init(self: Asset, aid: Any, fid: Any, quality: Any) -> object {
        self.aid = aid;
        self.fid = fid;
        self.quality = quality;
        self.dead = False;
    }
}
class MediaPipeline {
    def init(self: MediaPipeline) -> object {
        self.folders = {};
        self.assets = {};
        self.derived_from = {};
        self.score = {};
    }
    def add_folder(self: MediaPipeline, fid: Any, parent: Any = None) -> object {
        if (fid in self.folders) {
            raise ValueError("duplicate folder");
        }
        p = self.folders[parent] if (parent is not None) else None;
        f = Folder(fid, p);
        if (p is not None) {
            p.children.append(f);
        }
        self.folders[fid] = f;
        return fid;
    }
    def _folder_subtree(self: MediaPipeline, fid: Any) -> list {
        out: list = [];
        stack: list = [fid];
        while len(stack) > 0 {
            cur: str = stack.pop() as str;
            out.append(cur);
            kids = (self.folders[cur] as Folder).children as list;
            for c in kids {
                cf = c as Folder;
                stack.append(cf.fid);
            }
        }
        return out;
    }
    def add_asset(self: MediaPipeline, aid: Any, fid: Any, quality: Any = 0) -> object {
        if (aid in self.assets) {
            raise ValueError("duplicate asset");
        }
        if (fid not in self.folders) {
            raise KeyError(fid);
        }
        self.assets[aid] = Asset(aid, fid, quality);
        cur: Folder | None = self.folders[fid] as Folder | None;
        while (cur is not None) {
            cf: str = cur.fid as str;
            self.score[cf] = self.score.get(cf, 0) + quality;
            ups: list[Folder] = [cur <-:ParentFolder:<-];
            nxt: Folder | None = ups[0] if (len(ups) > 0) else None;
            cur = nxt;
        }
    }
    """Create dst as a derivative render of src."""
    def derive(
        self: MediaPipeline, src_aid: Any, dst_aid: Any, fid: Any, quality: Any = 0
    ) -> object {
        self.add_asset(dst_aid, fid, quality);
        self.derived_from[dst_aid] = src_aid;
    }
    """Transitive derivative closure (stack walk, cycle safe)."""
    def derivatives_of(self: MediaPipeline, aid: Any) -> list {
        seen = set();
        stack: list = [];
        for d in self.src_links_of(aid) as list {
            stack.append(d);
        }
        while len(stack) > 0 {
            cur: str = stack.pop() as str;
            if ((cur in seen) or (cur == aid)) {
                continue;
            }
            seen.add(cur);
            for d2 in self.src_links_of(cur) as list {
                stack.append(d2);
            }
        }
        return sorted(seen);
    }

    """Direct derivative ids of an asset (helper)."""
    def src_links_of(self: MediaPipeline, src_aid: Any) -> list {
        out: list = [];
        for dst in self.derived_from.keys() {
            if (self.derived_from[dst] == src_aid) {
                out.append(dst);
            }
        }
        return out;
    }
    """Live assets inside a folder subtree."""
    def folder_assets(
        self: MediaPipeline, fid: Any, include_sub: Any = True
    ) -> object {
        fids = self._folder_subtree(fid) as list;
        keep: list = [];
        for a in self.assets.values() as list {
            aa = a as Asset;
            if ((not aa.dead) and (aa.fid in fids)) {
                keep.append(aa.aid);
            }
        }
        return sorted(keep);
    }
    def folder_score(self: MediaPipeline, fid: Any) -> object {
        return self.score.get(fid, 0);
    }
    """Cascade-purge the asset and all derivatives transitively.
        Recomputes ancestor folder scores afterwards."""
    def purge(self: MediaPipeline, aid: Any) -> object {
        if (aid not in self.assets) {
            raise KeyError(aid);
        }
        doomed = [aid] + self.derivatives_of(aid);
        for d in doomed {
            a = self.assets.pop(d);
            a.dead = True;
            self.derived_from.pop(d, None);
            aa = a as Asset;
            home = aa.fid as str;
            cf2: Folder | None = self.folders[home] as Folder | None;
            while (cf2 is not None) {
                cfid: str = cf2.fid as str;
                self.score[cfid] = self.score.get(cfid, 0) - aa.quality;
                ups2: list[Folder] = [cf2 <-:ParentFolder:<-];
                nxt2: Folder | None = ups2[0] if (len(ups2) > 0) else None;
                cf2 = nxt2;
            }
        }
        for d in `list(self.derived_from) {
            if (
                (self.derived_from[d] in doomed)
                or (self.derived_from[d] not in self.assets)
            ) {
                delete(self.derived_from[d],);
            }
        }
        return sorted(doomed);
    }
}

