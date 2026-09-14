"""Idiomatic OSP lift for Pascapone/pibo#750."""

node LegacySession {
    has sid: str;
    has pi_session_id: str = "";
    has room_id: str = "";
    has parent_id: str = "";
    has updated_at: str = "";
}

node Session {
    has sid: str;
    has pi_session_id: str = "";
    has room_id: str = "";
    has metadata_room_id: str = "";
    has parent_id: str = "";
    has updated_at: str = "";
}

edge ParentLink {}

obj MigrationStore {
    has session_index: dict[str, Session] = {};
}

walker SessionLineage {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Session entry {
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        self.found.append(here.sid);
        print(here.sid);
        for kid in [here ->:ParentLink:->][?:Session] {
            visit :0: [kid];
        }
    }
}

def _link_parent(store: MigrationStore, child_id: str, parent_id: str) -> bool {
    if child_id not in store.session_index {
        return False;
    }
    if parent_id not in store.session_index {
        return False;
    }
    child: Session = store.session_index[child_id];
    parent: Session = store.session_index[parent_id];
    child +>:ParentLink:+> parent;
    return True;
}

def migrate_sessions_to_v2(
    store: MigrationStore,
    rows: list[LegacySession]
) -> dict[str, int] {
    counts: dict[str, int] = {
        "inserted": 0,
        "updated": 0,
        "skipped": 0
    };

    for row in rows {
        if row.sid in store.session_index {
            existing: Session = store.session_index[row.sid];
            if row.updated_at > existing.updated_at {
                existing.room_id = row.room_id;
                existing.metadata_room_id = row.room_id;
                existing.parent_id = row.parent_id;
                existing.updated_at = row.updated_at;
                counts["updated"] += 1;
            } else {
                counts["skipped"] += 1;
            }
        } else {
            target = Session(
                sid=row.sid,
                pi_session_id=row.pi_session_id,
                room_id=row.room_id,
                metadata_room_id=row.room_id,
                parent_id=row.parent_id,
                updated_at=row.updated_at
            );
            store.session_index[row.sid] = target;
            counts["inserted"] += 1;
        }
    }

    for row in rows {
        if row.parent_id != "" {
            _link_parent(store, row.sid, row.parent_id);
        }
    }
    return counts;
}

def session_room_id(store: MigrationStore, sid: str) -> str {
    if sid not in store.session_index {
        return "";
    }
    return store.session_index[sid].room_id;
}

def lineage_ids(store: MigrationStore, sid: str) -> list[str] {
    root_node: Session | None = None;
    if sid in store.session_index {
        root_node = store.session_index[sid];
    }
    if root_node is None {
        return [];
    }
    w = root_node spawn SessionLineage(claimed={});
    return sorted(w.found);
}
