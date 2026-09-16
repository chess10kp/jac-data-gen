"""CherryHQ/cherry-studio#16994 — Topic/Session pagination, grouping, and refresh."""

node Record {
    has id: str;
    has title: str;
    has owner_id: str;
    has seq: int;
}

node CursorPage {
    has key: str;
    has stale: bool = False;
}

edge NextPage {}
edge PageItem {}

walker PaginateWalker {
    has claimed: dict[str, bool] = {};
    has limit: int = 20;
    has start_key: str = "";
    has collected: list[str] = [];
    has next_cursor: str = "";
    has has_next: bool = False;
    has armed: bool = False;

    can step_page with CursorPage entry {
        if here.key in self.claimed {
            skip;
        }
        self.claimed[here.key] = True;
        if self.start_key != "" and here.key != self.start_key and not self.armed {
            nxt_skip: list[CursorPage] = [here ->:NextPage:->][?:CursorPage];
            if len(nxt_skip) > 0 {
                visit :0: nxt_skip;
            } else {
                disengage;
            }
        } else {
            self.armed = True;
            items: list[Record] = [here ->:PageItem:->][?:Record];
            for it in items {
                if len(self.collected) < self.limit {
                    self.collected.append(it.id);
                }
            }
            if len(self.collected) >= self.limit {
                nxt_cap: list[CursorPage] = [here ->:NextPage:->][?:CursorPage];
                if len(nxt_cap) > 0 {
                    self.next_cursor = nxt_cap[0].key;
                    self.has_next = True;
                }
                print ["paginate_cap", here.key, len(self.collected)];
                disengage;
            }
            nxt_walk: list[CursorPage] = [here ->:NextPage:->][?:CursorPage];
            if len(nxt_walk) > 0 {
                visit :0: nxt_walk;
            } else {
                print ["paginate_done", here.key, len(self.collected)];
                disengage;
            }
        }
    }
}

walker GroupWalker {
    has claimed: dict[str, bool] = {};
    has want_ids: list[str] | None = None;
    has want_set: dict[str, bool] = {};
    has buckets: dict[str, list[str]] = {};

    can bucket_record with Record entry {
        if here.id in self.claimed {
            skip;
        }
        self.claimed[here.id] = True;
        if self.want_ids is not None {
            for wid in self.want_ids {
                self.want_set[wid] = True;
            }
        }
        if here.id in self.want_set {
            if here.owner_id not in self.buckets {
                empty_bucket: list[str] = [];
                self.buckets[here.owner_id] = empty_bucket;
            }
            self.buckets[here.owner_id].append(here.id);
        }
        print ["group_scan", here.id, here.owner_id];
    }
}

walker InvalidateCollectWalker {
    has claimed: dict[str, bool] = {};
    has written_id: str = "";
    has stale_keys: list[str] = [];
    has cascade: bool = False;

    can collect_page with CursorPage entry {
        if here.key in self.claimed {
            skip;
        }
        self.claimed[here.key] = True;
        page_items: list[Record] = [here ->:PageItem:->][?:Record];
        for it in page_items {
            if it.id == self.written_id {
                self.cascade = True;
            }
        }
        if self.cascade {
            self.stale_keys.append(here.key);
        }
        nxt_inv: list[CursorPage] = [here ->:NextPage:->][?:CursorPage];
        if len(nxt_inv) > 0 {
            visit :0: nxt_inv;
        } else {
            print ["invalidate_collect_done", len(self.stale_keys)];
            disengage;
        }
    }
}

walker MarkStaleWalker {
    has claimed: dict[str, bool] = {};
    has target_key: str = "";

    can mark_page with CursorPage entry {
        if here.key in self.claimed {
            skip;
        }
        self.claimed[here.key] = True;
        if here.key == self.target_key {
            here.stale = True;
            print ["mark_stale", here.key];
            disengage;
        }
        nxt_mark: list[CursorPage] = [here ->:NextPage:->][?:CursorPage];
        if len(nxt_mark) > 0 {
            visit :0: nxt_mark;
        } else {
            disengage;
        }
    }
}

walker FilterWalker {
    has claimed: dict[str, bool] = {};
    has ids: list[str] | None = None;
    has query: str = "";
    has pinned: list[str] | None = None;
    has id_set: dict[str, bool] = {};
    has pinned_set: dict[str, bool] = {};
    has out_ids: list[str] = [];

    can filter_record with Record entry {
        if here.id in self.claimed {
            skip;
        }
        self.claimed[here.id] = True;
        if self.ids is not None {
            for iid in self.ids {
                self.id_set[iid] = True;
            }
        }
        if self.pinned is not None {
            for pid in self.pinned {
                self.pinned_set[pid] = True;
            }
        }
        if here.id in self.id_set {
            keep: bool = False;
            if self.query == "" {
                keep = True;
            } else if here.title.find(self.query) >= 0 {
                keep = True;
            }
            if keep {
                self.out_ids.append(here.id);
            }
        }
        print ["filter_scan", here.id, len(self.out_ids)];
    }
}

def paginate_topics(graph_root: node, cursor: str | None, limit: int) -> tuple[list[str], str | None, bool] {
    sk: str = "";
    if cursor is not None {
        sk = cursor;
    }
    w = graph_root spawn PaginateWalker(limit=limit, start_key=sk);
    nc: str | None = None;
    if w.next_cursor != "" {
        nc = w.next_cursor;
    }
    return (w.collected, nc, w.has_next);
}

def group_by_owner(graph_root: node, ids: list[str]) -> dict[str, list[str]] {
    g = graph_root spawn GroupWalker(want_ids=ids);
    out: dict[str, list[str]] = {};
    for owner_key in g.buckets {
        rows: list[str] = g.buckets[owner_key];
        sorted_rows: list[str] = sorted(rows);
        out[owner_key] = sorted_rows;
    }
    return out;
}

def filter_topics(
    graph_root: node,
    ids: list[str],
    query: str = "",
    pinned: list[str] | None = None
) -> list[str] {
    w = graph_root spawn FilterWalker(ids=ids, query=query, pinned=pinned);
    out_sorted: list[str] = sorted(w.out_ids);
    return out_sorted;
}

def pages_stale_after_write(graph_root: node, written_id: str) -> list[str] {
    w = graph_root spawn InvalidateCollectWalker(written_id=written_id);
    stale_sorted: list[str] = sorted(w.stale_keys);
    return stale_sorted;
}

def mark_page_stale(graph_root: node, page_key: str) -> bool {
    graph_root spawn MarkStaleWalker(target_key=page_key);
    return True;
}
