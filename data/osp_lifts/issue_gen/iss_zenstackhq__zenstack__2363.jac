"""ZenStack views, materialized views, and recursive CTE hierarchy — zenstackhq/zenstack#2363."""

node SchemaRoot {
    has rid: str = "registry";
}

node ViewRecord {
    has name: str;
    has view_type: str;
    has query: str;
    has refresh_on_migrate: bool = False;
    has allow_roles: list[str] = [];
    has materialized_fresh: bool = False;
}

node OrgUnit {
    has cid: str;
    has parent_id: str = "";
}

edge Defines {}
edge ReportsTo {}

walker OrgHierarchyWalker {
    has by_id: dict[str, OrgUnit] = {};
    has claimed: dict[str, bool] = {};
    has rows: list[dict] = {};
    has current_depth: int = 1;

    can start_roots with entry {
        root_units: list[OrgUnit] = [];
        for cid in self.by_id {
            nd = self.by_id[cid];
            if nd.parent_id == "" {
                root_units.append(nd);
            }
        }
        if len(root_units) > 0 {
            visit :0: root_units;
        } else {
            disengage;
        }
    }

    can descend with OrgUnit entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        row: dict = {};
        row["id"] = here.cid;
        row["parentId"] = here.parent_id;
        row["depth"] = self.current_depth;
        self.rows.append(row);
        print("cte_row", here.cid, self.current_depth);
        kids: list[OrgUnit] = [here ->:ReportsTo:->][?:OrgUnit];
        saved_depth = self.current_depth;
        if len(kids) > 0 {
            self.current_depth = saved_depth + 1;
            visit :0: kids;
            self.current_depth = saved_depth;
        } else {
            disengage;
        }
    }
}

walker OrgHierarchyCoordinator {
    has by_id: dict[str, OrgUnit] = {};
    has claimed: dict[str, bool] = {};
    has rows: list[dict] = {};

    can launch with entry {
        wk = root spawn OrgHierarchyWalker(
            by_id=self.by_id,
            claimed=self.claimed,
            rows=self.rows,
            current_depth=1
        );
        print("hierarchy_done", len(self.rows));
    }
}

def sort_hierarchy_rows(rows: list[dict]) -> list[dict] {
    out: list[dict] = [];
    for r in rows {
        out.append(r);
    }
    n = len(out);
    i = 0;
    while i < n {
        j = i + 1;
        while j < n {
            if (out[j]["id"] as str) < (out[i]["id"] as str) {
                tmp = out[i];
                out[i] = out[j];
                out[j] = tmp;
            }
            j += 1;
        }
        i += 1;
    }
    return out;
}

def build_registry -> SchemaRoot {
    reg = SchemaRoot();
    root ++> reg;
    return reg;
}

def register_view(
    reg: SchemaRoot,
    name: str,
    view_type: str,
    query: str,
    refresh_on_migrate: bool = False,
    allow_roles: list[str] | None = None
) {
    roles: list[str] = [];
    if allow_roles is not None {
        roles = allow_roles;
    }
    vr = ViewRecord(
        name=name,
        view_type=view_type,
        query=query,
        refresh_on_migrate=refresh_on_migrate,
        allow_roles=roles,
        materialized_fresh=False
    );
    reg +>: Defines:+> vr;
}

def get_view_type(reg: SchemaRoot, name: str) -> str | None {
    kids: list[ViewRecord] = [reg ->:Defines:->][?:ViewRecord];
    for vr in kids {
        if vr.name == name {
            return vr.view_type;
        }
    }
    return None;
}

def refresh_materialized_on_migrate(reg: SchemaRoot) -> list[str] {
    refreshed: list[str] = [];
    kids: list[ViewRecord] = [reg ->:Defines:->][?:ViewRecord];
    for vr in kids {
        if vr.view_type == "materialized" and vr.refresh_on_migrate {
            vr.materialized_fresh = True;
            refreshed.append(vr.name);
        }
    }
    return sorted(refreshed);
}

def can_read_view(reg: SchemaRoot, name: str, role: str | None) -> bool {
    if role is None {
        return False;
    }
    kids: list[ViewRecord] = [reg ->:Defines:->][?:ViewRecord];
    for vr in kids {
        if vr.name == name {
            if len(vr.allow_roles) == 0 {
                return True;
            }
            for ar in vr.allow_roles {
                if ar == role {
                    return True;
                }
            }
            return False;
        }
    }
    return False;
}

def evaluate_org_hierarchy(units: list[dict]) -> list[dict] {
    by_id: dict[str, OrgUnit] = {};
    for u in units {
        uid = u["id"] as str;
        pid = "";
        if "parentId" in u {
            if u["parentId"] is not None {
                pid = u["parentId"] as str;
            }
        }
        nd = OrgUnit(cid=uid, parent_id=pid);
        root ++> nd;
        by_id[uid] = nd;
    }
    for u in units {
        uid = u["id"] as str;
        pid = "";
        if "parentId" in u {
            if u["parentId"] is not None {
                pid = u["parentId"] as str;
            }
        }
        if pid != "" {
            by_id[pid] +>: ReportsTo:+> by_id[uid];
        }
        if "extra_parents" in u {
            extras = u["extra_parents"] as list[str];
            for ep in extras {
                if ep in by_id {
                    by_id[ep] +>: ReportsTo:+> by_id[uid];
                }
            }
        }
    }
    claimed: dict[str, bool] = {};
    rows: list[dict] = [];
    wk = root spawn OrgHierarchyCoordinator(
        by_id=by_id,
        claimed=claimed,
        rows=rows
    );
    return sort_hierarchy_rows(wk.rows);
}
