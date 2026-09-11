"""Media asset pipeline with derivative tracking.

Assets live in nested folders; each derived render points back at its
source asset. Purging an asset cascades to every derivative transitively,
and folder quality aggregates are maintained up the folder tree.

Hand-rolled machinery:
- parent/children pointers over the folder tree (C1)
- derivation adjacency dict with stack walks and visited guards (C2)
- queue-based cascade sweep plus ancestor aggregation (C5)
"""


class Folder:
    def __init__(self, fid, parent=None):
        self.fid = fid
        self.parent = parent
        self.children = []


class Asset:
    def __init__(self, aid, fid, quality):
        self.aid = aid
        self.fid = fid
        self.quality = quality
        self.dead = False


class MediaPipeline:
    def __init__(self):
        self.folders = {}    # fid -> Folder
        self.assets = {}     # aid -> Asset
        self.derived_from = {}  # derivative aid -> source aid
        self.score = {}      # fid -> total quality of live assets within

    def add_folder(self, fid, parent=None):
        if fid in self.folders:
            raise ValueError("duplicate folder " + fid)
        p = self.folders[parent] if parent is not None else None
        f = Folder(fid, p)
        if p is not None:
            p.children.append(f)
        self.folders[fid] = f
        return fid

    def _folder_subtree(self, fid):
        out = []
        stack = [fid]
        while stack:
            cur = stack.pop()
            out.append(cur)
            stack.extend(c.fid for c in self.folders[cur].children)
        return out

    def add_asset(self, aid, fid, quality=0):
        if aid in self.assets:
            raise ValueError("duplicate asset " + aid)
        if fid not in self.folders:
            raise KeyError(fid)
        self.assets[aid] = Asset(aid, fid, quality)
        cur_fid = fid
        while cur_fid is not None:       # ancestor-aware aggregation
            self.score[cur_fid] = self.score.get(cur_fid, 0) + quality
            cur_fid = (self.folders[cur_fid].parent.fid
                       if self.folders[cur_fid].parent else None)

    def derive(self, src_aid, dst_aid, fid, quality=0):
        """Create dst as a derivative render of src."""
        self.add_asset(dst_aid, fid, quality)
        self.derived_from[dst_aid] = src_aid

    def derivatives_of(self, aid):
        """Transitive derivative closure (stack walk, cycle safe)."""
        seen = set()
        stack = [d for d, s in self.derived_from.items() if s == aid]
        while stack:
            cur = stack.pop()
            if cur in seen or cur == aid:
                continue
            seen.add(cur)
            stack.extend(d for d, s in self.derived_from.items()
                         if s == cur)
        return sorted(seen)

    def folder_assets(self, fid, include_sub=True):
        """Live assets inside a folder subtree."""
        fids = set(self._folder_subtree(fid)) if include_sub else {fid}
        return sorted(a.aid for a in self.assets.values()
                      if not a.dead and a.fid in fids)

    def folder_score(self, fid):
        return self.score.get(fid, 0)

    def purge(self, aid):
        """Cascade-purge the asset and all derivatives transitively.
        Recomputes ancestor folder scores afterwards."""
        if aid not in self.assets:
            raise KeyError(aid)
        doomed = [aid] + self.derivatives_of(aid)
        for d in doomed:
            a = self.assets.pop(d)
            a.dead = True
            self.derived_from.pop(d, None)
            # per-asset ancestor-aware recomputation along its own chain
            cur_fid = a.fid
            while cur_fid is not None:
                self.score[cur_fid] = self.score.get(cur_fid, 0) - a.quality
                parent = self.folders[cur_fid].parent
                cur_fid = parent.fid if parent else None
        # drop links pointing at purged assets
        for d in list(self.derived_from):
            if (self.derived_from[d] in doomed
                    or self.derived_from[d] not in self.assets):
                del self.derived_from[d]
        return sorted(doomed)
